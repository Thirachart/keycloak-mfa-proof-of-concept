<#import "field.ftl" as field>
<#import "footer.ftl" as loginFooter>

<#macro username>
  <#assign label>
    <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
  </#assign>
  <@field.group name="username" label=label>
    <div class="${properties.kcInputGroup}">
      <div class="${properties.kcInputGroupItemClass} ${properties.kcFill}">
        <span class="${properties.kcInputClass} ${properties.kcFormReadOnlyClass}">
          <input id="kc-attempted-username" value="${auth.attemptedUsername}" readonly>
        </span>
      </div>
      <div class="${properties.kcInputGroupItemClass}">
        <button id="reset-login" class="${properties.kcFormPasswordVisibilityButtonClass} kc-login-tooltip" type="button"
                aria-label="${msg('restartLoginTooltip')}" onclick="location.href='${url.loginRestartFlowUrl}'">
          <i class="fa-sync-alt fas" aria-hidden="true"></i>
          <span class="kc-tooltip-text">${msg("restartLoginTooltip")}</span>
        </button>
      </div>
    </div>
  </@field.group>
</#macro>

<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<!DOCTYPE html>
<html class="${properties.kcHtmlClass!}" lang="${lang!"th"}"<#if realm.internationalizationEnabled> dir="${(locale.rtl)?then('rtl','ltr')}"</#if>>
<head>
  <meta charset="utf-8">
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="color-scheme" content="light">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <#if properties.meta?has_content>
    <#list properties.meta?split(' ') as meta>
      <meta name="${meta?split('==')[0]}" content="${meta?split('==')[1]}"/>
    </#list>
  </#if>
  <title>${title!msg("loginTitle",(realm.displayName!''))}</title>
  <link rel="icon" type="image/x-icon" href="${url.resourcesPath}/img/newlogo.png"/>
  <#if properties.stylesCommon?has_content>
    <#list properties.stylesCommon?split(' ') as style>
      <link href="${url.resourcesCommonPath}/${style}" rel="stylesheet" />
    </#list>
  </#if>
  <#if properties.styles?has_content>
    <#list properties.styles?split(' ') as style>
      <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
    </#list>
  </#if>
  <script type="importmap">
    {
      "imports": {
        "rfc4648": "${url.resourcesCommonPath}/vendor/rfc4648/rfc4648.js"
      }
    }
  </script>
  <#if properties.scripts?has_content>
    <#list properties.scripts?split(' ') as script>
      <script src="${url.resourcesPath}/${script}" type="text/javascript"></script>
    </#list>
  </#if>
  <#if scripts??>
    <#list scripts as script>
      <script src="${script}" type="text/javascript"></script>
    </#list>
  </#if>
  <script type="module" src="${url.resourcesPath}/js/passwordVisibility.js"></script>
  <script type="module">
    <#outputformat "JavaScript">
    import { startSessionPolling } from ${(url.resourcesPath + "/js/authChecker.js")?c};
    startSessionPolling(${url.ssoLoginInOtherTabsUrl?c});
    </#outputformat>
  </script>
  <script type="module">
    document.addEventListener("click", (event) => {
      const link = event.target.closest("a[data-once-link]");
      if (!link) return;
      if (link.getAttribute("aria-disabled") === "true") {
        event.preventDefault();
        return;
      }
      const { disabledClass } = link.dataset;
      if (disabledClass) link.classList.add(...disabledClass.trim().split(/\s+/));
      link.setAttribute("role", "link");
      link.setAttribute("aria-disabled", "true");
    });
  </script>
  <#if authenticationSession??>
    <script type="module">
      <#outputformat "JavaScript">
      import { checkAuthSession } from ${(url.resourcesPath + "/js/authChecker.js")?c};
      checkAuthSession(${authenticationSession.authSessionIdHash?c});
      </#outputformat>
    </script>
  </#if>
  <script>
    // Preserve the parent Keycloak template compatibility workaround.
    const isFirefox = true;
  </script>
</head>
<body id="keycloak-bg" class="${properties.kcBodyClass!} pattaya-inherited-page ${bodyClass}" data-page-id="login-${pageId}">
  <div class="login-container">
    <div class="login-left-panel" aria-hidden="true"></div>

    <div class="login-right-panel">
      <div class="login-form-wrapper">
        <div class="login-header">
          <h1 class="system-title-en">PATTAYA FINANCIAL AND ACCOUNTING SYSTEM</h1>
          <h2 class="system-title-th">ระบบการเงินและบัญชีเมืองพัทยา</h2>
        </div>

        <section class="pattaya-flow-section" role="main">
          <div class="pattaya-flow-heading-row">
            <h3 class="update-password-title pattaya-flow-title" id="kc-page-title"><#nested "header"></h3>
            <#if realm.internationalizationEnabled && locale.supported?size gt 1>
              <select class="pattaya-language-select" aria-label="${msg("languages")}" id="login-select-toggle"
                      onchange="if (this.value) window.location.href=this.value">
                <#list locale.supported?sort_by("label") as l>
                  <option value="${l.url}" ${(l.languageTag == locale.currentLanguageTag)?then('selected','')}>${l.label}</option>
                </#list>
              </select>
            </#if>
          </div>

          <#if !(auth?has_content && auth.showUsername() && !auth.showResetCredentials())>
            <#if displayRequiredFields>
              <p class="pattaya-required-fields"><span aria-hidden="true">*</span> ${msg("requiredFields")}</p>
            </#if>
          <#else>
            <#if displayRequiredFields>
              <p class="pattaya-required-fields"><span aria-hidden="true">*</span> ${msg("requiredFields")}</p>
            </#if>
            <div class="pattaya-inherited-form pattaya-shown-username">
              <#nested "show-username">
              <@username />
            </div>
          </#if>

          <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
            <div class="alert-box pattaya-alert-${message.type!'info'}" role="alert">
              <span class="kc-feedback-text">${message.summary}</span>
            </div>
          </#if>

          <div class="pattaya-inherited-form">
            <#nested "form">
          </div>

          <#if auth?has_content && auth.showTryAnotherWayLink()>
            <form id="kc-select-try-another-way-form" class="pattaya-inherited-form" action="${url.loginAction}" method="post" novalidate="novalidate">
              <input type="hidden" name="tryAnotherWay" value="on"/>
              <a id="try-another-way" href="javascript:document.forms['kc-select-try-another-way-form'].requestSubmit()" class="btn-cancel pattaya-action-link">
                ${msg("doTryAnotherWay")}
              </a>
            </form>
          </#if>

          <div class="pattaya-social-providers">
            <#nested "socialProviders">
          </div>

          <#if displayInfo>
            <div id="kc-info" class="pattaya-flow-info">
              <#nested "info">
            </div>
          </#if>

          <div class="pattaya-keycloak-footer">
            <@loginFooter.content/>
          </div>
        </section>
      </div>
    </div>
  </div>
</body>
</html>
</#macro>

<#macro simplePage title>
  <@registrationLayout displayMessage=false; section>
    <#if section = "header">
      ${title}
    <#elseif section = "form">
      <#nested>
    </#if>
  </@registrationLayout>
</#macro>
