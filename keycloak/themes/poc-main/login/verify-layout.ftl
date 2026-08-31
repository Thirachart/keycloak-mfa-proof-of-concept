<#macro page title>
<!DOCTYPE html>
<html lang="${lang!"th"}">
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <title>${title}</title>
  <link rel="stylesheet" href="${url.resourcesPath}/css/poc.css" />
</head>
<body class="poc-verify-body">
  <main class="poc-verify-card" role="main">
    <div class="poc-verify-brand">
      <img class="poc-verify-logo" src="${url.resourcesPath}/img/newlogo.png" alt="PFAS" width="40" height="40" />
      <div class="poc-verify-brand-copy">
        <div class="poc-verify-brand-name">PFAS</div>
        <div class="poc-verify-brand-subtitle">ระบบการเงินและบัญชีเมืองพัทยา</div>
      </div>
    </div>
    <div class="poc-verify-divider"></div>
    <h1 class="poc-verify-title">${title}</h1>
    <#nested>
    <div class="poc-verify-divider poc-verify-divider-footer"></div>
    <p class="poc-verify-note">หากท่านไม่ได้เป็นผู้ทำรายการนี้ กรุณาเพิกเฉยและไม่ต้องดำเนินการใด ๆ เพิ่มเติม</p>
  </main>
  <footer class="poc-verify-footer">&copy; เมืองพัทยา &middot; ระบบการเงินและบัญชีเมืองพัทยา (PFAS)</footer>
</body>
</html>
</#macro>
