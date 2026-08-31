<#import "verify-layout.ftl" as verify>
<#import "user-profile-commons.ftl" as userProfileCommons>
<@verify.page title="เปลี่ยนอีเมล">
    <p class="poc-verify-copy">
        ระบุอีเมลใหม่ที่ต้องการใช้งาน ระบบจะส่งลิงก์ยืนยันไปยังอีเมลใหม่ก่อนเปลี่ยนข้อมูลในบัญชี
    </p>

    <#if message?has_content>
        <div class="poc-update-email-message poc-update-email-message-${message.type!"info"}" role="alert">
            ${kcSanitize(message.summary)?no_esc}
        </div>
    </#if>

    <form id="kc-update-email-form" class="poc-update-email-form" action="${url.loginAction}" method="post">
        <@userProfileCommons.userProfileFormFields/>

        <div class="poc-verify-actions poc-update-email-actions">
            <button id="poc-update-email-submit" class="poc-verify-button poc-verify-button-primary" type="submit">
                บันทึกและส่งอีเมลยืนยัน
            </button>
            <#if isAppInitiatedAction??>
                <button id="poc-update-email-cancel" class="poc-verify-button poc-verify-button-secondary" type="submit" name="cancel-aia" value="true" formnovalidate>
                    ยกเลิก
                </button>
            </#if>
        </div>
    </form>
</@verify.page>
