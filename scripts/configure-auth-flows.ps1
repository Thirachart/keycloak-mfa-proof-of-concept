param(
  [bool]$TrustedDeviceEnabled = $true,
  [Alias('TrustDays')]
  [int]$MfaTrustDays = 30
)

$ErrorActionPreference = 'Stop'
$base = 'http://localhost:18080'
$realmName = 'poc'
$phase1 = 'poc-phase1-browser-v2'
$phase2 = 'poc-phase2-browser-v3'
$postBrokerPhase2 = 'poc-external-idp-post-login-phase2-v2'
$localMfaSubflow = 'poc-phase2-trusted-mfa'
$brokerMfaSubflow = 'poc-post-broker-trusted-mfa'
$trustDays = if ($MfaTrustDays -gt 0) { $MfaTrustDays } else { 30 }
$trustedDeviceEnabledValue = $TrustedDeviceEnabled.ToString().ToLowerInvariant()

$token = (Invoke-RestMethod -Method Post -Uri "$base/realms/master/protocol/openid-connect/token" -ContentType 'application/x-www-form-urlencoded' -Body @{
  client_id = 'admin-cli'
  username = 'admin'
  password = 'admin'
  grant_type = 'password'
}).access_token
$headers = @{ Authorization = "Bearer $token" }

$userProfile = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/users/profile" -Headers $headers
if ($userProfile.unmanagedAttributePolicy -ne 'ADMIN_EDIT') {
  $userProfile | Add-Member -NotePropertyName unmanagedAttributePolicy -NotePropertyValue 'ADMIN_EDIT' -Force
  Invoke-RestMethod -Method Put -Uri "$base/admin/realms/$realmName/users/profile" -Headers $headers -ContentType 'application/json' -Body ($userProfile | ConvertTo-Json -Depth 30)
  Write-Host 'Configured unmanaged user attributes as ADMIN_EDIT so server-side MFA trust can be inspected and revoked through Admin REST.'
}

function Get-Flows {
  Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows" -Headers $headers
}

function Ensure-BrowserCopy([string]$alias) {
  if (-not ((Get-Flows) | Where-Object { $_.alias -eq $alias })) {
    $source = [uri]::EscapeDataString('browser')
    Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/flows/$source/copy" -Headers $headers -ContentType 'application/json' -Body (@{ newName = $alias } | ConvertTo-Json)
    Write-Host "Created independent browser flow: $alias"
  }
}

function Ensure-TopLevelFlow([string]$alias, [string]$description) {
  if (-not ((Get-Flows) | Where-Object { $_.alias -eq $alias })) {
    Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/flows" -Headers $headers -ContentType 'application/json' -Body (@{
      alias = $alias
      description = $description
      providerId = 'basic-flow'
      topLevel = $true
      builtIn = $false
    } | ConvertTo-Json)
    Write-Host "Created authentication flow: $alias"
  }
}

function Set-ExecutionRequirement([string]$flowAlias, $execution, [string]$requirement) {
  if ($execution.requirement -ne $requirement) {
    $execution.requirement = $requirement
    Invoke-RestMethod -Method Put -Uri "$base/admin/realms/$realmName/authentication/flows/$flowAlias/executions" -Headers $headers -ContentType 'application/json' -Body ($execution | ConvertTo-Json -Depth 20)
  }
}

function Add-Execution([string]$containerAlias, [string]$providerId) {
  $encodedContainer = [uri]::EscapeDataString($containerAlias)
  Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/flows/$encodedContainer/executions/execution" -Headers $headers -ContentType 'application/json' -Body (@{ provider = $providerId } | ConvertTo-Json)
}

function Add-Subflow([string]$containerAlias, [string]$subflowAlias, [string]$description) {
  $encodedContainer = [uri]::EscapeDataString($containerAlias)
  Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/flows/$encodedContainer/executions/flow" -Headers $headers -ContentType 'application/json' -Body (@{
    alias = $subflowAlias
    type = 'basic-flow'
    provider = 'registration-page-form'
    description = $description
  } | ConvertTo-Json)
}

function Set-ExecutionConfig($execution, [string]$alias, [hashtable]$config) {
  $payload = @{ alias = $alias; config = $config } | ConvertTo-Json -Depth 10
  if ($execution.authenticationConfig) {
    Invoke-RestMethod -Method Put -Uri "$base/admin/realms/$realmName/authentication/config/$($execution.authenticationConfig)" -Headers $headers -ContentType 'application/json' -Body $payload | Out-Null
  } else {
    Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/executions/$($execution.id)/config" -Headers $headers -ContentType 'application/json' -Body $payload | Out-Null
  }
}

function Ensure-TrustedMfaSubflow(
  [string]$rootFlowAlias,
  [string]$containerAlias,
  [string]$subflowAlias,
  [string]$emailConfigAlias,
  [string]$recorderConfigAlias
) {
  $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
  $subflowExecution = $executions | Where-Object { $_.authenticationFlow -eq $true -and $_.displayName -eq $subflowAlias } | Select-Object -First 1
  if (-not $subflowExecution) {
    Add-Subflow $containerAlias $subflowAlias 'Skip MFA for a browser with a valid server-side trusted-device record; otherwise run Email OTP and remember the browser.'
    Write-Host "Created conditional trusted-device MFA subflow: $subflowAlias"
    $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
    $subflowExecution = $executions | Where-Object { $_.authenticationFlow -eq $true -and $_.displayName -eq $subflowAlias } | Select-Object -First 1
  }

  if (-not $subflowExecution) { throw "Could not find subflow execution $subflowAlias under $rootFlowAlias." }
  Set-ExecutionRequirement $rootFlowAlias $subflowExecution 'CONDITIONAL'

  $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
  $condition = $executions | Where-Object { $_.providerId -eq 'poc-trusted-device-condition' -and $_.level -gt $subflowExecution.level } | Select-Object -First 1
  if (-not $condition) {
    Add-Execution $subflowAlias 'poc-trusted-device-condition'
    $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
    $condition = $executions | Where-Object { $_.providerId -eq 'poc-trusted-device-condition' } | Select-Object -Last 1
    Write-Host "Added trusted-device condition to $subflowAlias."
  }
  Set-ExecutionRequirement $rootFlowAlias $condition 'CONDITIONAL'
  Set-ExecutionConfig $condition "$subflowAlias-trust-condition" @{ trustedDeviceEnabled = $trustedDeviceEnabledValue }
  $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers

  $selector = $executions | Where-Object { $_.providerId -eq 'poc-mfa-method-selector' -and $_.level -gt $subflowExecution.level } | Select-Object -First 1
  if (-not $selector) {
    Add-Execution $subflowAlias 'poc-mfa-method-selector'
    $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
    $selector = $executions | Where-Object { $_.providerId -eq 'poc-mfa-method-selector' } | Select-Object -Last 1
    Write-Host "Added MFA selector to $subflowAlias."
  }
  Set-ExecutionRequirement $rootFlowAlias $selector 'REQUIRED'

  $email = $executions | Where-Object { $_.providerId -eq 'email-authenticator' -and $_.level -gt $subflowExecution.level } | Select-Object -First 1
  if (-not $email) {
    Add-Execution $subflowAlias 'email-authenticator'
    $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
    $email = $executions | Where-Object { $_.providerId -eq 'email-authenticator' } | Select-Object -Last 1
    Write-Host "Added Email OTP to $subflowAlias."
  }
  Set-ExecutionRequirement $rootFlowAlias $email 'REQUIRED'
  Set-ExecutionConfig $email $emailConfigAlias @{ skipSetup = 'true' }

  $recorder = $executions | Where-Object { $_.providerId -eq 'poc-trusted-device-recorder' -and $_.level -gt $subflowExecution.level } | Select-Object -First 1
  if (-not $recorder) {
    Add-Execution $subflowAlias 'poc-trusted-device-recorder'
    $executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$rootFlowAlias/executions" -Headers $headers
    $recorder = $executions | Where-Object { $_.providerId -eq 'poc-trusted-device-recorder' } | Select-Object -Last 1
    Write-Host "Added trusted-device recorder to $subflowAlias."
  }
  Set-ExecutionRequirement $rootFlowAlias $recorder 'REQUIRED'
  Set-ExecutionConfig $recorder $recorderConfigAlias @{ trustDays = $trustDays.ToString(); trustedDeviceEnabled = $trustedDeviceEnabledValue }
}

Ensure-BrowserCopy $phase1
Ensure-BrowserCopy $phase2
Ensure-TopLevelFlow $postBrokerPhase2 'Phase 2 optional post-broker MFA with a 30-day server-side trusted-browser record.'

$phase2Executions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows/$phase2/executions" -Headers $headers
$forms = $phase2Executions | Where-Object { $_.authenticationFlow -eq $true -and $_.level -eq 0 -and $_.displayName -like '* forms' } | Select-Object -First 1
if (-not $forms) { throw 'Could not locate copied browser forms subflow.' }

Ensure-TrustedMfaSubflow $phase2 $forms.displayName $localMfaSubflow 'poc-email-otp-trusted-local' 'poc-trusted-device-local-30d'
Ensure-TrustedMfaSubflow $postBrokerPhase2 $postBrokerPhase2 $brokerMfaSubflow 'poc-email-otp-trusted-broker' 'poc-trusted-device-broker-30d'

Write-Host "Phase 1 flow: $phase1"
Write-Host "Phase 2 flow: $phase2"
Write-Host "Post-broker Phase 2 flow: $postBrokerPhase2"
Write-Host "MFA trust period: $trustDays days; trusted_device_enabled=$trustedDeviceEnabledValue. Trust is created automatically after successful Email OTP."
Write-Host 'Built-in browser flow remains unchanged.'
