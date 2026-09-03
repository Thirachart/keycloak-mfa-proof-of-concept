<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>${msg("loginTitle",(realm.displayName!''))}</title>
    <link href="${url.resourcesPath}/css/pattaya-login.css" rel="stylesheet" />
    <link rel="icon" type="image/x-icon" href="${url.resourcesPath}/img/newlogo.png"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
  <div class="login-container">

    <div class="login-left-panel" aria-hidden="true"></div>

    <div class="login-right-panel">
        <div class="login-form-wrapper">

            <div class="login-header">
                <h1 class="system-title-en">PATTAYA FINANCIAL AND ACCOUNTING SYSTEM</h1>
                <h2 class="system-title-th">ระบบการเงินและบัญชีเมืองพัทยา</h2>
            </div>

            <#if message?has_content && (message.type!'') == 'error'>
                <div class="alert-box">
                    ${message.summary?no_esc}
                </div>
            </#if>

            <#if realm.password>
                <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">

                    <div class="form-group">
                        <label for="username" class="form-label">
                            <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
                        </label>
                        <input id="username" class="form-control" name="username" value="${(login.username)!''}" type="text" autofocus autocomplete="off" />
                    </div>

                    <div class="form-group">
                        <label for="password" class="form-label">${msg("password")}</label>
                        <div class="password-wrapper">
                            <input id="password" class="form-control" name="password" type="password" autocomplete="off" />
                            <button type="button" class="toggle-password" onclick="togglePassword()" tabindex="-1" aria-label="แสดง/ซ่อนรหัสผ่าน">
                                <i id="toggle-icon" class="fa fa-eye"></i>
                            </button>
                        </div>
                    </div>

                    <div class="form-options-group">
                        <#-- Remember Me and Forgot Password are hidden for now — see docs/design-decisions.md #9.
                        <#if realm.rememberMe && !usernameHidden??>
                            <div class="checkbox-item">
                                <label>
                                    <#if login.rememberMe??>
                                        <input id="rememberMe" name="rememberMe" type="checkbox" checked> ${msg("rememberMe")}
                                    <#else>
                                        <input id="rememberMe" name="rememberMe" type="checkbox"> ${msg("rememberMe")}
                                    </#if>
                                </label>
                            </div>
                        </#if>

                        <#if realm.resetPasswordAllowed>
                            <div class="forgot-link">
                                <a href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a>
                            </div>
                        </#if>
                        -->
                    </div>

                    <div class="form-group">
                        <button class="btn-primary" name="login" id="kc-login" type="submit">
                            ${msg("doLogIn")}
                        </button>
                    </div>
                </form>
            </#if>

            <#if realm.password && social?? && social.providers?has_content>
                <div class="separator">
                    <span>หรือเข้าสู่ระบบด้วย</span>
                </div>

                <div class="social-login-list">
                    <#list social.providers as p>
                        <a href="${p.loginUrl}" id="social-${p.alias}" class="btn-social">
                            <i class="fa fa-sign-in" aria-hidden="true" style="margin-right:8px;"></i>
                            <span>${p.displayName!}</span>
                        </a>
                    </#list>
                </div>
            </#if>

            <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
                <div class="register-link">
                    <span>${msg("noAccount")} <a href="${url.registrationUrl}">${msg("doRegister")}</a></span>
                </div>
            </#if>

        </div>
    </div>
  </div>
  <script>
    function togglePassword() {
      var input = document.getElementById('password');
      var icon = document.getElementById('toggle-icon');
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
