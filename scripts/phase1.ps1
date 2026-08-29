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
$realm.verifyEmail = $false
$realm.browserFlow = 'poc-phase1-browser-v2'
if ($realm.PSObject.Properties['passwordPolicy']) {
  $realm.passwordPolicy = ''
} else {
  $realm | Add-Member -NotePropertyName passwordPolicy -NotePropertyValue ''
}
Invoke-RestMethod -Method Put -Uri "$base/admin/realms/poc" -Headers $headers -ContentType 'application/json' -Body ($realm | ConvertTo-Json -Depth 100)

try {
  $idp = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/poc/identity-provider/instances/lab-idp" -Headers $headers
  if ($idp.PSObject.Properties['postBrokerLoginFlowAlias']) {
    $idp.postBrokerLoginFlowAlias = $null
  } else {
    $idp | Add-Member -NotePropertyName postBrokerLoginFlowAlias -NotePropertyValue $null
  }
  Invoke-RestMethod -Method Put -Uri "$base/admin/realms/poc/identity-provider/instances/lab-idp" -Headers $headers -ContentType 'application/json' -Body ($idp | ConvertTo-Json -Depth 100)
} catch {
  if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw }
}

Invoke-RestMethod -Method Post -Uri "$base/admin/realms/poc/logout-all" -Headers $headers | Out-Null
Write-Host 'Phase 1 active: poc-phase1-browser-v2; email verification optional; Email OTP disabled; 180-day password expiration disabled. Existing sessions logged out.'
