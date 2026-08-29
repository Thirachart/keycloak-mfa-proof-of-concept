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
$realm.verifyEmail = $true
$realm.browserFlow = 'poc-phase2-browser-v3'
if ($realm.PSObject.Properties['passwordPolicy']) {
  $realm.passwordPolicy = 'forceExpiredPasswordChange(180)'
} else {
  $realm | Add-Member -NotePropertyName passwordPolicy -NotePropertyValue 'forceExpiredPasswordChange(180)'
}
Invoke-RestMethod -Method Put -Uri "$base/admin/realms/poc" -Headers $headers -ContentType 'application/json' -Body ($realm | ConvertTo-Json -Depth 100)

try {
  $idp = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/poc/identity-provider/instances/lab-idp" -Headers $headers
  $requireMfaAfterBroker = $false
  if ($idp.config -and $idp.config.PSObject.Properties['require_mfa_after_broker']) {
    $requireMfaAfterBroker = [System.Convert]::ToBoolean($idp.config.require_mfa_after_broker)
  }

  $postBrokerFlow = if ($requireMfaAfterBroker) { 'poc-external-idp-post-login-phase2-v2' } else { $null }
  if ($idp.PSObject.Properties['postBrokerLoginFlowAlias']) {
    $idp.postBrokerLoginFlowAlias = $postBrokerFlow
  } else {
    $idp | Add-Member -NotePropertyName postBrokerLoginFlowAlias -NotePropertyValue $postBrokerFlow
  }
  Invoke-RestMethod -Method Put -Uri "$base/admin/realms/poc/identity-provider/instances/lab-idp" -Headers $headers -ContentType 'application/json' -Body ($idp | ConvertTo-Json -Depth 100)
  Write-Host "External IdP lab-idp: require_mfa_after_broker=$requireMfaAfterBroker; postBrokerLoginFlowAlias=$postBrokerFlow"
} catch {
  if ($_.Exception.Response.StatusCode.value__ -ne 404) { throw }
}

Invoke-RestMethod -Method Post -Uri "$base/admin/realms/poc/logout-all" -Headers $headers | Out-Null
Write-Host 'Phase 2 active: poc-phase2-browser-v3; verified email required; Email OTP uses 30-day trusted-browser records; local passwords expire after 180 days. Existing sessions logged out.'
