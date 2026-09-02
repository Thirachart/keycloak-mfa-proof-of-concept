<#import "verify-layout.ftl" as verify>
<#assign otpLength = (codeLength!6)>
<@verify.page title="ยืนยันรหัส OTP">
    <#if messagesPerField.existsError('emailCode')>
        <div class="poc-card-message poc-card-message-error" role="alert">
            ${kcSanitize(messagesPerField.get('emailCode'))?no_esc}
        </div>
    <#elseif message?has_content && (message.type!'') == 'error'>
        <div class="poc-card-message poc-card-message-error" role="alert">
            ${message.summary?no_esc}
        </div>
    </#if>

    <form id="kc-otp-login-form" class="poc-card-form" action="${url.loginAction}" method="post">
        <p class="poc-verify-copy poc-card-intro">
            ${msg("emailOtpForm", otpLength)}<#if maskedEmail??><br/><strong>${kcSanitize(maskedEmail)?no_esc}</strong></#if>
        </p>

        <div class="poc-card-field">
            <input id="emailCode" name="emailCode" autocomplete="off" type="text" class="poc-card-control poc-otp-input"
                   autofocus maxlength="${otpLength?c}"
                   aria-label="รหัส OTP"
                   aria-invalid="<#if messagesPerField.existsError('emailCode')>true</#if>"
                   <#if maxAttemptsReached?? && maxAttemptsReached>disabled</#if> />
        </div>

        <div class="poc-verify-actions poc-card-actions poc-card-actions-stacked">
            <#if !(maxAttemptsReached?? && maxAttemptsReached)>
                <button class="poc-verify-button poc-verify-button-primary" name="login" type="submit">${msg("doLogIn")}</button>
            </#if>
            <button class="poc-verify-button poc-verify-button-secondary" name="resend" type="submit">${msg("resendCode")}</button>
            <button class="poc-verify-button poc-verify-button-secondary" name="cancel" type="submit">${msg("doCancel")}</button>
        </div>
    </form>
</@verify.page>
