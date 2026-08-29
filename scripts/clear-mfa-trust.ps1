param(
  [Parameter(Mandatory = $true)]
  [string]$Username
)

$ErrorActionPreference = 'Stop'
$base = 'http://localhost:18080'
$realmName = 'poc'
$attributeNames = @('poc_mfa_trusted_device', 'poc_mfa_trusted_until')

$token = (Invoke-RestMethod -Method Post -Uri "$base/realms/master/protocol/openid-connect/token" -ContentType 'application/x-www-form-urlencoded' -Body @{
  client_id = 'admin-cli'
  username = 'admin'
  password = 'admin'
  grant_type = 'password'
}).access_token
$headers = @{ Authorization = "Bearer $token" }

$encodedUsername = [uri]::EscapeDataString($Username)
$users = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/users?username=$encodedUsername&exact=true" -Headers $headers
$user = $users | Select-Object -First 1
if (-not $user) {
  throw "User '$Username' was not found in realm '$realmName'."
}

if (-not $user.attributes) {
  Write-Host "User '$Username' has no trusted-device records."
  exit 0
}

$attributes = @{}
$user.attributes.PSObject.Properties | ForEach-Object {
  if ($attributeNames -notcontains $_.Name) {
    $attributes[$_.Name] = $_.Value
  }
}
$user.attributes = $attributes

Invoke-RestMethod -Method Put -Uri "$base/admin/realms/$realmName/users/$($user.id)" -Headers $headers -ContentType 'application/json' -Body ($user | ConvertTo-Json -Depth 30)
Write-Host "Cleared all server-side MFA trust for '$Username' (device records and account-wide trust). Existing browser trust cookies will no longer validate."
