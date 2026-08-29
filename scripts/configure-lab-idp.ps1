param(
  [ValidateSet('true', 'false')]
  [string]$RequireMfaAfterBroker = 'false'
)

$ErrorActionPreference = 'Stop'
$base = 'http://localhost:18080'
$realmName = 'poc'
$firstBrokerFlow = 'poc-lab-first-login'

$token = (Invoke-RestMethod -Method Post -Uri "$base/realms/master/protocol/openid-connect/token" -ContentType 'application/x-www-form-urlencoded' -Body @{
  client_id = 'admin-cli'
  username = 'admin'
  password = 'admin'
  grant_type = 'password'
}).access_token
$headers = @{ Authorization = "Bearer $token" }

$flows = Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/authentication/flows" -Headers $headers
if (-not ($flows | Where-Object { $_.alias -eq $firstBrokerFlow })) {
  $sourceAlias = [uri]::EscapeDataString('first broker login')
  Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/authentication/flows/$sourceAlias/copy" -Headers $headers -ContentType 'application/json' -Body (@{ newName = $firstBrokerFlow } | ConvertTo-Json)
  Write-Host "Created independent first broker login flow: $firstBrokerFlow"
}

$representation = @{
  alias = 'lab-idp'
  displayName = 'External Identity Provider Lab'
  providerId = 'oidc'
  enabled = $true
  updateProfileFirstLoginMode = 'on'
  trustEmail = $false
  storeToken = $false
  addReadTokenRoleOnCreate = $false
  authenticateByDefault = $false
  linkOnly = $false
  firstBrokerLoginFlowAlias = $firstBrokerFlow
  postBrokerLoginFlowAlias = $null
  config = @{
    clientId = 'poc-broker'
    clientSecret = 'poc-broker-secret'
    authorizationUrl = 'http://localhost:18080/realms/external-idp/protocol/openid-connect/auth'
    tokenUrl = 'http://keycloak:8080/realms/external-idp/protocol/openid-connect/token'
    logoutUrl = 'http://localhost:18080/realms/external-idp/protocol/openid-connect/logout'
    userInfoUrl = 'http://keycloak:8080/realms/external-idp/protocol/openid-connect/userinfo'
    jwksUrl = 'http://keycloak:8080/realms/external-idp/protocol/openid-connect/certs'
    issuer = 'http://localhost:18080/realms/external-idp'
    defaultScope = 'openid profile email'
    useJwksUrl = 'true'
    validateSignature = 'true'
    syncMode = 'IMPORT'
    require_mfa_after_broker = $RequireMfaAfterBroker
  }
}

$body = $representation | ConvertTo-Json -Depth 20
try {
  Invoke-RestMethod -Method Get -Uri "$base/admin/realms/$realmName/identity-provider/instances/lab-idp" -Headers $headers | Out-Null
  Invoke-RestMethod -Method Put -Uri "$base/admin/realms/$realmName/identity-provider/instances/lab-idp" -Headers $headers -ContentType 'application/json' -Body $body
  Write-Host 'Updated lab IdP.'
} catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 404) {
    Invoke-RestMethod -Method Post -Uri "$base/admin/realms/$realmName/identity-provider/instances" -Headers $headers -ContentType 'application/json' -Body $body
    Write-Host 'Created lab IdP.'
  } else {
    throw
  }
}

Write-Host "Lab IdP ready. require_mfa_after_broker=$RequireMfaAfterBroker"
Write-Host 'External user: external-demo / external1234 (email demo@example.com)'
Write-Host 'The first broker login uses an independent copy flow; built-in first broker login is not modified.'
