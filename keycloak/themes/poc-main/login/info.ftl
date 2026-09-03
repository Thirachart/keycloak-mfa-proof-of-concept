<#import "app-links.ftl" as app>
<#assign isVerifyEmailInfo = messageHeader?? && (messageHeader == "confirmEmailAddressVerificationHeader" || messageHeader == msg("confirmEmailAddressVerificationHeader"))>
<#assign isEmailVerifiedDone = messageHeader?? && (messageHeader == "emailVerifiedMessageHeader" || messageHeader == "emailVerifiedAlreadyMessageHeader" || messageHeader == msg("emailVerifiedMessageHeader") || messageHeader == msg("emailVerifiedAlreadyMessageHeader"))>
<#assign isEmailUpdateSent = messageHeader?? && (messageHeader == "emailUpdateConfirmationSentTitle" || messageHeader == msg("emailUpdateConfirmationSentTitle"))>
<#assign isEmailUpdated = messageHeader?? && (messageHeader == "emailUpdatedTitle" || messageHeader == msg("emailUpdatedTitle"))>
<#assign isAccountUpdated = messageHeader?? && (messageHeader == "accountUpdatedTitle" || messageHeader == msg("accountUpdatedTitle"))>
<#assign isPasswordUpdated = isAccountUpdated && message?has_content && (message.summary == msg("accountPasswordUpdatedMessage"))>
<#assign isPasswordResetCompleted = isPasswordUpdated && !(pageRedirectUri?has_content) && !(actionUri?has_content)>

<#if isVerifyEmailInfo>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="ยืนยันอีเมลของคุณ">
        <p class="poc-verify-copy">
            กรุณากดปุ่มด้านล่างเพื่อยืนยันความเป็นเจ้าของอีเมลนี้ และดำเนินการยืนยันอีเมลให้เสร็จสมบูรณ์
        </p>

        <#if actionUri?has_content>
            <div class="poc-verify-actions">
                <a id="poc-verify-proceed" class="poc-verify-button poc-verify-button-primary" href="${actionUri}" data-once-link>
                    ยืนยันอีเมล
                </a>
                <a id="poc-change-email" class="poc-verify-button poc-verify-button-secondary" href="${app.appUpdateEmailUrl()}">
                    เปลี่ยนอีเมล
                </a>
            </div>
        <#elseif pageRedirectUri?has_content>
            <div class="poc-verify-actions">
                <a class="poc-verify-button poc-verify-button-primary" href="${pageRedirectUri}">
                    กลับไปยังระบบ
                </a>
            </div>
        </#if>
    </@verify.page>
<#elseif isEmailVerifiedDone>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="ยืนยันอีเมลสำเร็จ">
        <p id="poc-email-verified-message" class="poc-verify-copy">
            ${message.summary}
        </p>
        <div class="poc-verify-actions">
            <#if pageRedirectUri?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${pageRedirectUri}">กลับไปยังระบบ</a>
            <#elseif actionUri?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${actionUri}">ดำเนินการต่อ</a>
            <#elseif (client.baseUrl)?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${client.baseUrl}">กลับไปยังระบบ</a>
            <#else>
                <a class="poc-verify-button poc-verify-button-primary" href="${properties.pocAppBaseUrl}/">กลับไปยังระบบ</a>
            </#if>
        </div>
    </@verify.page>
<#elseif isEmailUpdateSent>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="${msg('emailUpdateConfirmationSentTitle')}">
        <p id="poc-email-update-message" class="poc-verify-copy">
            ${message.summary}
        </p>
        <p class="poc-verify-copy poc-verify-copy-secondary">
            กรุณาเปิดอีเมลใหม่และกดลิงก์ยืนยันเพื่อให้การเปลี่ยนอีเมลเสร็จสมบูรณ์
        </p>
        <div class="poc-verify-actions">
            <a id="poc-change-email-again" class="poc-verify-button poc-verify-button-secondary" href="${app.appUpdateEmailUrl()}">
                เปลี่ยนอีเมลอีกครั้ง
            </a>
            <#if pageRedirectUri?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${pageRedirectUri}">กลับไปยังระบบ</a>
            <#elseif actionUri?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${actionUri}">ดำเนินการต่อ</a>
            <#elseif (client.baseUrl)?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${client.baseUrl}">กลับไปยังระบบ</a>
            <#else>
                <a class="poc-verify-button poc-verify-button-primary" href="${properties.pocAppBaseUrl}/">กลับไปยังระบบ</a>
            </#if>
        </div>
    </@verify.page>
<#elseif isEmailUpdated>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="${msg('emailUpdatedTitle')}">
        <p id="poc-email-updated-message" class="poc-verify-copy">
            ${message.summary}
        </p>
        <div class="poc-verify-actions">
            <#if pageRedirectUri?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${pageRedirectUri}">กลับไปยังระบบ</a>
            <#elseif actionUri?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${actionUri}">ดำเนินการต่อ</a>
            <#elseif (client.baseUrl)?has_content>
                <a class="poc-verify-button poc-verify-button-primary" href="${client.baseUrl}">กลับไปยังระบบ</a>
            <#else>
                <a class="poc-verify-button poc-verify-button-primary" href="${properties.pocAppBaseUrl}/">กลับไปยังระบบ</a>
            </#if>
        </div>
    </@verify.page>
<#elseif isPasswordResetCompleted>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="เปลี่ยนรหัสผ่านสำเร็จ">
        <p id="poc-password-updated-message" class="poc-verify-copy">
            รหัสผ่านของคุณได้รับการเปลี่ยนเรียบร้อยแล้ว กรุณาเข้าสู่ระบบอีกครั้งด้วยรหัสผ่านใหม่
        </p>
        <div class="poc-verify-actions">
            <a id="poc-password-login" class="poc-verify-button poc-verify-button-primary" href="${app.appLoginUrl()}">
                เข้าสู่ระบบด้วยรหัสผ่านใหม่
            </a>
        </div>
    </@verify.page>
<#elseif isPasswordUpdated>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="เปลี่ยนรหัสผ่านสำเร็จ">
        <p id="poc-password-updated-message" class="poc-verify-copy">
            ${message.summary}
        </p>
        <div class="poc-verify-actions">
            <#if pageRedirectUri?has_content>
                <a id="poc-password-return" class="poc-verify-button poc-verify-button-primary" href="${pageRedirectUri}">กลับไปยังระบบ</a>
            <#elseif actionUri?has_content>
                <a id="poc-password-continue" class="poc-verify-button poc-verify-button-primary" href="${actionUri}">ดำเนินการต่อ</a>
            <#elseif (client.baseUrl)?has_content>
                <a id="poc-password-return" class="poc-verify-button poc-verify-button-primary" href="${client.baseUrl}">กลับไปยังระบบ</a>
            <#else>
                <a id="poc-password-return" class="poc-verify-button poc-verify-button-primary" href="${properties.pocAppBaseUrl}/">กลับไปยังระบบ</a>
            </#if>
        </div>
    </@verify.page>
<#elseif isAccountUpdated>
    <#import "verify-layout.ftl" as verify>
    <@verify.page title="${msg('accountUpdatedTitle')}">
        <p id="poc-account-updated-message" class="poc-verify-copy">
            ${message.summary}
        </p>
        <div class="poc-verify-actions">
            <#if pageRedirectUri?has_content>
                <a id="poc-account-return" class="poc-verify-button poc-verify-button-primary" href="${pageRedirectUri}">กลับไปยังระบบ</a>
            <#elseif actionUri?has_content>
                <a id="poc-account-continue" class="poc-verify-button poc-verify-button-primary" href="${actionUri}">ดำเนินการต่อ</a>
            <#elseif (client.baseUrl)?has_content>
                <a id="poc-account-return" class="poc-verify-button poc-verify-button-primary" href="${client.baseUrl}">กลับไปยังระบบ</a>
            <#else>
                <a id="poc-account-return" class="poc-verify-button poc-verify-button-primary" href="${properties.pocAppBaseUrl}/">กลับไปยังระบบ</a>
            </#if>
        </div>
    </@verify.page>
<#else>
    <#import "template.ftl" as layout>
    <@layout.registrationLayout displayMessage=false; section>
        <#if section = "header">
            <#if messageHeader??>
                ${kcSanitize(msg("${messageHeader}"))?no_esc}
            <#else>
                ${message.summary}
            </#if>
        <#elseif section = "form">
            <div id="kc-info-message">
                <p class="instruction">${message.summary}<#if requiredActions??><#list requiredActions>: <b><#items as reqActionItem>${kcSanitize(msg("requiredAction.${reqActionItem}"))?no_esc}<#sep>, </#items></b></#list></#if></p>
                <#if !skipLink??>
                    <#if pageRedirectUri?has_content>
                        <p><a href="${pageRedirectUri}">${msg("backToApplication")}</a></p>
                    <#elseif actionUri?has_content>
                        <p><a href="${actionUri}">${msg("proceedWithAction")}</a></p>
                    <#elseif (client.baseUrl)?has_content>
                        <p><a href="${client.baseUrl}">${msg("backToApplication")}</a></p>
                    </#if>
                </#if>
            </div>
        </#if>
    </@layout.registrationLayout>
</#if>
