<#import "verify-layout.ftl" as verify>
<@verify.page title="เลือกวิธียืนยันตัวตน">
    <#if message?has_content && (message.type!'') == 'error'>
        <div class="poc-card-message poc-card-message-error" role="alert">
            ${message.summary?no_esc}
        </div>
    </#if>

    <form id="kc-mfa-method-selector-form" class="poc-card-form" action="${url.loginAction}" method="post">
        <p class="poc-verify-copy poc-card-intro">กรุณาเลือกวิธีที่ต้องการใช้ยืนยันตัวตนสำหรับการเข้าสู่ระบบครั้งนี้</p>

        <label class="poc-mfa-option" for="mfa-email">
            <input id="mfa-email" type="radio" name="mfa_method" value="email" checked />
            <span>
                <strong>รหัส OTP ทางอีเมล</strong>
                <small>ส่งรหัสใช้ครั้งเดียวไปยังอีเมลที่ยืนยันแล้วของคุณ</small>
            </span>
        </label>

        <div class="poc-mfa-option poc-mfa-disabled" aria-disabled="true">
            <input type="radio" disabled />
            <span>
                <strong>แอปยืนยันตัวตน</strong>
                <small>ยังไม่เปิดใช้งานใน PoC นี้</small>
            </span>
        </div>

        <div class="poc-mfa-option poc-mfa-disabled" aria-disabled="true">
            <input type="radio" disabled />
            <span>
                <strong>พาสคีย์ / WebAuthn</strong>
                <small>ยังไม่เปิดใช้งานใน PoC นี้</small>
            </span>
        </div>

        <div class="poc-verify-actions poc-card-actions">
            <button class="poc-verify-button poc-verify-button-primary" type="submit">${msg("doContinue")}</button>
        </div>
    </form>
</@verify.page>
