<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>${msg("loginTitle",(realm.displayName!''))}</title>
    <link href="${url.resourcesPath}/css/pattaya-login.css" rel="stylesheet" />
    <link rel="icon" type="image/x-icon" href="${url.resourcesPath}/img/newlogo.png"/>
</head>
<body>
  <div class="login-container">

    <div class="login-left-panel" aria-hidden="true"></div>

    <div class="login-right-panel">
        <div class="login-form-wrapper">

            <div class="login-header">
                <h1 class="system-title-en">PATTAYA FINANCIAL AND ACCOUNTING SYSTEM</h1>
                <h2 class="system-title-th">เลือกวิธียืนยันตัวตน</h2>
            </div>

            <#if message?has_content && (message.type!'') == 'error'>
                <div class="alert-box">
                    ${message.summary?no_esc}
                </div>
            </#if>

            <form id="kc-mfa-method-selector-form" action="${url.loginAction}" method="post">
                <p class="mfa-intro">กรุณาเลือกวิธีที่ต้องการใช้ยืนยันตัวตนสำหรับการเข้าสู่ระบบครั้งนี้</p>

                <label class="mfa-option" for="mfa-email">
                    <input id="mfa-email" type="radio" name="mfa_method" value="email" checked />
                    <span>
                        <strong>รหัส OTP ทางอีเมล</strong>
                        <small>ส่งรหัสใช้ครั้งเดียวไปยังอีเมลที่ยืนยันแล้วของคุณ</small>
                    </span>
                </label>

                <div class="mfa-option mfa-option-disabled" aria-disabled="true">
                    <input type="radio" disabled />
                    <span>
                        <strong>แอปยืนยันตัวตน</strong>
                        <small>ยังไม่เปิดใช้งานใน PoC นี้</small>
                    </span>
                </div>

                <div class="mfa-option mfa-option-disabled" aria-disabled="true">
                    <input type="radio" disabled />
                    <span>
                        <strong>พาสคีย์ / WebAuthn</strong>
                        <small>ยังไม่เปิดใช้งานใน PoC นี้</small>
                    </span>
                </div>

                <div class="mfa-actions">
                    <button class="btn-primary" type="submit">${msg("doContinue")}</button>
                </div>
            </form>

        </div>
    </div>
  </div>
</body>
</html>
