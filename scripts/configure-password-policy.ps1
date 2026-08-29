$ErrorActionPreference = 'Stop'
$base = 'http://localhost:18080'

$token = (Invoke-RestMethod -Method Post -Uri "$base/realms/master/protocol/openid-connect/token" -ContentType 'application/x-www-form-urlencoded' -Body @{
  client_id = 'admin-cli'
  username = 'admin'
  password = 'admin'
  grant_type = 'password'
}).access_token

$headers = @{ Authorization = "Bearer $token" }
$realm = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/poc" -Headers $headers
if ($realm.PSObject.Properties['passwordPolicy']) {
  $realm.passwordPolicy = 'forceExpiredPasswordChange(180)'
} else {
  $realm | Add-Member -NotePropertyName passwordPolicy -NotePropertyValue 'forceExpiredPasswordChange(180)'
}
Invoke-RestMethod -Method Put -Uri "$base/admin/realms/poc" -Headers $headers -ContentType 'application/json' -Body ($realm | ConvertTo-Json -Depth 100)

$check = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/poc" -Headers $headers
if ($check.passwordPolicy -ne 'forceExpiredPasswordChange(180)') {
  throw "Unexpected password policy: $($check.passwordPolicy)"
}

Write-Host "Password policy active: $($check.passwordPolicy)"
Write-Host 'Users must change passwords after 180 days.'
