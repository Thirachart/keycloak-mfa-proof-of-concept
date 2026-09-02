param(
    [string]$Namespace = "pits-app",
    [string]$ConfigMapName = "pattaya-theme-config",
    [string]$ThemeName = "pattaya-theme",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$themeDir = Join-Path $repoRoot "keycloak\themes\poc-main"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "deploy\generated"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

if (-not (Test-Path $themeDir -PathType Container)) {
    throw "Theme directory not found: $themeDir"
}

$files = @(Get-ChildItem -Path $themeDir -Recurse -File | Sort-Object FullName)
if ($files.Count -eq 0) {
    throw "No theme files found under: $themeDir"
}

$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
$oneMiB = 1MB
if ($totalBytes -ge $oneMiB) {
    throw "poc-main is $totalBytes bytes. Kubernetes ConfigMap data must stay below 1 MiB. Use a custom Keycloak image instead."
}
if ($totalBytes -ge 900KB) {
    Write-Warning "poc-main is close to the 1 MiB ConfigMap limit ($totalBytes bytes). A custom Keycloak image is recommended."
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Get-RelativeThemePath([string]$fullPath) {
    $relative = $fullPath.Substring($themeDir.Length).TrimStart('\', '/')
    return $relative.Replace('\', '/')
}

function Get-ConfigMapKey([string]$relativePath) {
    # ConfigMap keys cannot contain '/'. Double underscores keep the original
    # directory boundaries readable while avoiding duplicate basenames.
    $key = $relativePath.Replace('/', '__').Replace('\', '__')
    $key = [regex]::Replace($key, '[^A-Za-z0-9._-]', '_')
    if ($key.Length -gt 253) {
        throw "Generated ConfigMap key is longer than 253 characters: $key"
    }
    return $key
}

$entries = @()
$keySet = @{}
foreach ($file in $files) {
    $relative = Get-RelativeThemePath $file.FullName
    $key = Get-ConfigMapKey $relative

    if ($keySet.ContainsKey($key)) {
        throw "ConfigMap key collision: '$relative' and '$($keySet[$key])' both map to '$key'"
    }
    $keySet[$key] = $relative

    $entries += [pscustomobject]@{
        Key = $key
        RelativePath = $relative
        FullPath = $file.FullName
        Size = $file.Length
    }
}

$configMapPath = Join-Path $OutputDir "configmap-pattaya-theme.yaml"
$mountPath = Join-Path $OutputDir "configmap-pattaya-theme-mount.yaml"

# Build YAML directly instead of piping kubectl output through Windows PowerShell.
# PowerShell 5 can decode UTF-8 stdout using the active console code page and corrupt
# Thai text into YAML control characters. Direct generation preserves UTF-8 exactly.
$textExtensions = @('.ftl', '.properties', '.css', '.js', '.html', '.htm', '.txt', '.xml', '.json', '.svg')
$textEntries = @($entries | Where-Object { $textExtensions -contains ([IO.Path]::GetExtension($_.FullPath).ToLowerInvariant()) })
$binaryEntries = @($entries | Where-Object { $textExtensions -notcontains ([IO.Path]::GetExtension($_.FullPath).ToLowerInvariant()) })

$yamlLines = New-Object System.Collections.Generic.List[string]
$yamlLines.Add('apiVersion: v1')
$yamlLines.Add('kind: ConfigMap')
$yamlLines.Add('metadata:')
$yamlLines.Add("  name: $ConfigMapName")
$yamlLines.Add("  namespace: $Namespace")

if ($binaryEntries.Count -gt 0) {
    $yamlLines.Add('binaryData:')
    foreach ($entry in $binaryEntries) {
        $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($entry.FullPath))
        $yamlLines.Add("  $($entry.Key): $base64")
    }
}

if ($textEntries.Count -gt 0) {
    $yamlLines.Add('data:')
    foreach ($entry in $textEntries) {
        $yamlLines.Add("  $($entry.Key): |-")
        $text = [IO.File]::ReadAllText($entry.FullPath, [Text.Encoding]::UTF8)
        # Normalize line endings for stable Kubernetes manifests while preserving content.
        $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
        $contentLines = $text.Split("`n")
        # |− chomping removes the final newline, so trim only the synthetic empty line
        # produced when the source file itself ends with a newline.
        if ($contentLines.Count -gt 0 -and $contentLines[-1] -eq '') {
            $contentLines = $contentLines[0..($contentLines.Count - 2)]
        }
        foreach ($contentLine in $contentLines) {
            $yamlLines.Add("    $contentLine")
        }
    }
}

# Write UTF-8 without BOM so the generated manifest works consistently in CI/CD.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText(
    $configMapPath,
    (($yamlLines -join "`n") + "`n"),
    $utf8NoBom
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Merge this snippet into spec.template.spec of the Keycloak Deployment/StatefulSet.")
$lines.Add("# It reconstructs keycloak/themes/poc-main exactly under /opt/keycloak/themes/$ThemeName.")
$lines.Add("volumes:")
$lines.Add("  - name: pattaya-theme")
$lines.Add("    configMap:")
$lines.Add("      name: $ConfigMapName")
$lines.Add("      items:")
foreach ($entry in $entries) {
    $lines.Add("        - key: $($entry.Key)")
    $lines.Add("          path: $($entry.RelativePath)")
}
$lines.Add("")
$lines.Add("containers:")
$lines.Add("  - name: keycloak")
$lines.Add("    volumeMounts:")
$lines.Add("      - name: pattaya-theme")
$lines.Add("        mountPath: /opt/keycloak/themes/$ThemeName")
$lines.Add("        readOnly: true")

[System.IO.File]::WriteAllText(
    $mountPath,
    (($lines -join [Environment]::NewLine) + [Environment]::NewLine),
    $utf8NoBom
)

Write-Host "Generated poc-main Kubernetes theme manifests"
Write-Host "  Theme files : $($entries.Count)"
Write-Host "  Theme size  : $totalBytes bytes ($([math]::Round($totalBytes / 1KB, 2)) KiB)"
Write-Host "  ConfigMap   : $configMapPath"
Write-Host "  Mount spec  : $mountPath"
Write-Host ""
Write-Host "Apply ConfigMap:"
Write-Host "  kubectl apply -f `"$configMapPath`""
Write-Host ""
Write-Host "Then merge the volume + volumeMount from:"
Write-Host "  $mountPath"
Write-Host ""
Write-Host "After changing the ConfigMap, restart Keycloak pods so the theme cache is refreshed:"
Write-Host "  kubectl rollout restart deployment/<keycloak-deployment> -n $Namespace"
