param(
  [Parameter(Mandatory = $true)]
  [string]$Username,
  [switch]$NoLogout
)

$ErrorActionPreference = 'Stop'
$base = 'http://localhost:18080'
$realmName = 'poc'

$token = (Invoke-RestMethod -Method Post -Uri "$base/realms/master/protocol/openid-connect/token" -ContentType 'application/x-www-form-urlencoded' -Body @{
  client_id = 'admin-cli'
  username = 'admin'
  password = 'admin'
  grant_type = 'password'
}).access_token
$headers = @{ Authorization = "Bearer $token" }

$requiredActions = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/required-actions" -Headers $headers
if (-not ($requiredActions | Where-Object { $_.alias -eq 'UPDATE_PROFILE' })) {
  Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/register-required-action" -Headers $headers -ContentType 'application/json' -Body '["UPDATE_PROFILE"]'
}

$users = @(Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/users?username=$([uri]::EscapeDataString($Username))&exact=true" -Headers $headers)
if ($users.Count -ne 1) {
  throw "Expected exactly one user named '$Username', found $($users.Count)."
}

$user = $users[0]
$actions = @($user.requiredActions)

if ([string]::IsNullOrWhiteSpace($user.email)) {
  $actions += 'UPDATE_PROFILE'
}

if ($user.emailVerified -ne $true) {
  $actions += 'VERIFY_EMAIL'
}

$actions = @($actions | Select-Object -Unique)
$user | Add-Member -NotePropertyName requiredActions -NotePropertyValue $actions -Force
$user | Add-Member -NotePropertyName emailVerified -NotePropertyValue ([bool]$user.emailVerified) -Force

Invoke-RestMethod -Method Put -Uri "$base/admin/realms/$realmName/users/$($user.id)" -Headers $headers -ContentType 'application/json' -Body ($user | ConvertTo-Json -Depth 20)

if (-not $NoLogout) {
  Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/users/$($user.id)/logout" -Headers $headers
}

Write-Host "Email-verification enforcement configured for '$Username'."
if ([string]::IsNullOrWhiteSpace($user.email)) {
  Write-Host 'Next login: UPDATE_PROFILE requires an email, then VERIFY_EMAIL blocks login until verification completes.'
} elseif ($user.emailVerified -ne $true) {
  Write-Host 'Next login: VERIFY_EMAIL blocks login until the current email is verified.'
} else {
  Write-Host 'Email is already verified; no verification action was added.'
}
Write-Host ("Required actions: " + ($actions -join ', '))
