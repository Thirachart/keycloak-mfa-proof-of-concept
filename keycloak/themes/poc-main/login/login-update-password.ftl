<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>${msg("updatePasswordTitle")}</title>
    <link href="${url.resourcesPath}/css/pattaya-login.css" rel="stylesheet" />
    <link rel="icon" type="image/x-icon" href="${url.resourcesPath}/img/newlogo.png"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
  <div class="login-container">

    <div class="login-left-panel">
        <img src="${url.resourcesPath}/img/newlogo.png" alt="PFAS" />
    </div>

    <div class="login-right-panel">
        <div class="login-form-wrapper">

            <div class="login-header">
                <h1 class="system-title-en">PATTAYA FINANCIAL AND ACCOUNTING SYSTEM</h1>
                <h2 class="system-title-th">ระบบการเงินและบัญชีเมืองพัทยา</h2>
            </div>

            <div class="update-password-title">
                <i class="fa fa-lock" style="margin-right:8px;color:#e65100;"></i>${msg("updatePasswordTitle")}
            </div>

            <#if message?has_content && (message.type!'') == 'error'>
                <div class="alert-box">
                    ${message.summary?no_esc}
                </div>
            </#if>

            <form id="kc-passwd-update-form" action="${url.loginAction}" method="post">
                <input type="text" id="username" name="username" value="${username!''}" autocomplete="username" readonly style="display:none;" />

                <div class="form-group">
                    <label for="password-new" class="form-label">${msg("passwordNew")}</label>
                    <div class="password-wrapper">
                        <input id="password-new" class="form-control" name="password-new" type="password" autofocus autocomplete="new-password" />
                        <button type="button" class="toggle-password" onclick="togglePassword('password-new','icon-new')" tabindex="-1" aria-label="แสดง/ซ่อนรหัสผ่านใหม่">
                            <i id="icon-new" class="fa fa-eye"></i>
                        </button>
                    </div>
                </div>

                <div class="form-group">
                    <label for="password-confirm" class="form-label">${msg("passwordConfirmNew")}</label>
                    <div class="password-wrapper">
                        <input id="password-confirm" class="form-control" name="password-confirm" type="password" autocomplete="new-password" />
                        <button type="button" class="toggle-password" onclick="togglePassword('password-confirm','icon-confirm')" tabindex="-1" aria-label="แสดง/ซ่อนยืนยันรหัสผ่าน">
                            <i id="icon-confirm" class="fa fa-eye"></i>
                        </button>
                    </div>
                </div>

                <div class="form-group" style="margin-top:8px;">
                    <button class="btn-primary" type="submit">
                        ${msg("doSubmit")}
                    </button>
                </div>

                <#if isAppInitiatedAction??>
                    <div class="form-group">
                        <button class="btn-cancel" type="submit" name="cancel-aia" value="true">
                            ${msg("doCancel")}
                        </button>
                    </div>
                </#if>
            </form>

        </div>
    </div>
  </div>
  <script>
    function togglePassword(inputId, iconId) {
      var input = document.getElementById(inputId);
      var icon = document.getElementById(iconId);
      if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
      } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
      }
    }
  </script>
</body>
</html>
