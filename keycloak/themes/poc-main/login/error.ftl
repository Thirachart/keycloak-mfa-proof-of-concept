<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>${msg("error")}</title>
    <link rel="icon" type="image/x-icon" href="${url.resourcesPath}/img/newlogo.png"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;600;700&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Sarabun', sans-serif; background: #fff; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .error-wrap { text-align: center; padding: 40px 24px; max-width: 480px; }
        .error-icon { font-size: 120px; font-weight: 700; color: #263238; line-height: 1; }
        .error-msg { font-size: 30px; font-weight: 700; color: #263238; margin: 16px 0 8px; }
        .error-summary { font-size: 15px; color: #90a4ae; margin: 0 0 12px; line-height: 1.6; }
        .error-detail { font-size: 16px; color: #546e7a; margin-bottom: 36px; line-height: 1.6; }
        .btn-home { display: inline-block; padding: 12px 36px; background: #263238; color: #fff; font-size: 16px; font-weight: 600; text-decoration: none; border-radius: 6px; transition: background 0.2s; }
        .btn-home:hover { background: #e65100; }
    </style>
</head>
<body>
  <div class="error-wrap">
      <div class="error-icon">
          <#if message?has_content && (message.type!'') == 'error'>
              <i class="fa fa-exclamation-triangle" style="font-size:100px;color:#c62828;"></i>
          <#elseif message?has_content && (message.type!'') == 'warning'>
              <i class="fa fa-exclamation-circle" style="font-size:100px;color:#e65100;"></i>
          <#else>
              <i class="fa fa-exclamation-circle" style="font-size:100px;color:#90a4ae;"></i>
          </#if>
      </div>
      <div class="error-msg">เกิดข้อผิดพลาด</div>
      <#if message?has_content>
          <div class="error-summary">${message.summary?no_esc}</div>
      </#if>
      <div class="error-detail">ระบบไม่สามารถดำเนินการได้<br/>กรุณาลองอีกครั้งหรือติดต่อผู้ดูแลระบบ</div>
      <#if client?? && client.baseUrl?has_content>
          <a href="${client.baseUrl}" class="btn-home">${msg("doBack")}</a>
      <#else>
          <a href="${url.loginUrl!'/'}" class="btn-home">${msg("doLogIn")}</a>
      </#if>
  </div>
</body>
</html>
