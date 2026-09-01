<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>${msg("doLogIn")}</title>
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
                <h2 class="system-title-th">ยืนยันรหัส OTP</h2>
            </div>

            <#if messagesPerField.existsError('emailCode')>
                <div class="alert-box" role="alert">
                    ${kcSanitize(messagesPerField.get('emailCode'))?no_esc}
                </div>
            <#elseif message?has_content && (message.type!'') == 'error'>
                <div class="alert-box" role="alert">
                    ${message.summary?no_esc}
                </div>
            </#if>

            <#assign otpLength = (codeLength!6)>
            <form id="kc-otp-login-form" action="${url.loginAction}" method="post">

                <p class="otp-hint">${msg("emailOtpForm", otpLength)}<#if maskedEmail??><br/><strong>${kcSanitize(maskedEmail)?no_esc}</strong></#if></p>

                <div class="form-group">
                    <input id="emailCode" name="emailCode" autocomplete="off" type="text" class="form-control otp-input"
                           autofocus maxlength="${otpLength?c}"
                           aria-invalid="<#if messagesPerField.existsError('emailCode')>true</#if>"
                           <#if maxAttemptsReached?? && maxAttemptsReached>disabled</#if> />

                </div>

                <div class="otp-buttons">
                    <#if !(maxAttemptsReached?? && maxAttemptsReached)>
                        <button class="btn-primary" name="login" type="submit">${msg("doLogIn")}</button>
                    </#if>
                    <button class="btn-cancel" name="resend" type="submit">${msg("resendCode")}</button>
                    <button class="btn-cancel" name="cancel" type="submit">${msg("doCancel")}</button>
                </div>
            </form>

        </div>
    </div>
  </div>
</body>
</html>
