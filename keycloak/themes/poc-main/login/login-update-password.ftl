<#import "verify-layout.ftl" as verify>
<@verify.page title="${msg('updatePasswordTitle')}">
    <#if message?has_content && (message.type!'') == 'error'>
        <div class="poc-card-message poc-card-message-error" role="alert">
            ${message.summary?no_esc}
        </div>
    </#if>

    <form id="kc-passwd-update-form" class="poc-card-form" action="${url.loginAction}" method="post">
        <input type="text" id="username" name="username" value="${username!''}" autocomplete="username" readonly style="display:none;" />

        <div class="poc-card-field">
            <label for="password-new">${msg("passwordNew")}</label>
            <div class="poc-password-wrapper">
                <input id="password-new" class="poc-card-control" name="password-new" type="password" autofocus autocomplete="new-password" />
                <button type="button" class="poc-password-toggle" onclick="togglePassword('password-new','toggle-new')" aria-label="แสดงหรือซ่อนรหัสผ่านใหม่">
                    <span id="toggle-new">แสดง</span>
                </button>
            </div>
        </div>

        <div class="poc-card-field">
            <label for="password-confirm">${msg("passwordConfirmNew")}</label>
            <div class="poc-password-wrapper">
                <input id="password-confirm" class="poc-card-control" name="password-confirm" type="password" autocomplete="new-password" />
                <button type="button" class="poc-password-toggle" onclick="togglePassword('password-confirm','toggle-confirm')" aria-label="แสดงหรือซ่อนยืนยันรหัสผ่าน">
                    <span id="toggle-confirm">แสดง</span>
                </button>
            </div>
        </div>

        <div class="poc-verify-actions poc-card-actions poc-card-actions-stacked">
            <button class="poc-verify-button poc-verify-button-primary" type="submit">
                ${msg("doSubmit")}
            </button>
            <#if isAppInitiatedAction??>
                <button class="poc-verify-button poc-verify-button-secondary" type="submit" name="cancel-aia" value="true">
                    ${msg("doCancel")}
                </button>
            </#if>
        </div>
    </form>

    <script>
      function togglePassword(inputId, labelId) {
        var input = document.getElementById(inputId);
        var label = document.getElementById(labelId);
        if (input.type === 'password') {
          input.type = 'text';
          label.textContent = 'ซ่อน';
        } else {
          input.type = 'password';
          label.textContent = 'แสดง';
        }
      }
    </script>

    <#if isAppInitiatedAction??>
      <script>
        (function () {
          var cookieName = 'poc_password_aia_state';

          function cookieSuffix() {
            var suffix = '; Path=/; SameSite=Lax';
            var host = window.location.hostname;
            if (window.location.protocol === 'https:') suffix += '; Secure';
            if (host === 'pfas.pattaya.go.th' || host.endsWith('.pfas.pattaya.go.th')) {
              suffix += '; Domain=.pfas.pattaya.go.th';
            }
            return suffix;
          }

          function setAiaState(value) {
            document.cookie = cookieName + '=' + encodeURIComponent(value) + cookieSuffix();
          }

          function clearAiaState() {
            document.cookie = cookieName + '=; Max-Age=0' + cookieSuffix();
          }

          <#if message?has_content && (message.type!'') == 'error'>
            setAiaState('error');
          <#else>
            clearAiaState();
          </#if>

          var form = document.getElementById('kc-passwd-update-form');
          if (form) {
            form.addEventListener('submit', function (event) {
              var submitter = event.submitter;
              if (submitter && submitter.name === 'cancel-aia') {
                setAiaState('cancelled');
              } else {
                setAiaState('submitted');
              }
            });
          }
        })();
      </script>
    </#if>
</@verify.page>
