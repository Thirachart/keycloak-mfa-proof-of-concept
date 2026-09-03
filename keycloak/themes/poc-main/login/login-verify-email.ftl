<#import "verify-layout.ftl" as verify>
<#import "app-links.ftl" as app>
<@verify.page title="ยืนยันอีเมลของคุณ">
    <#assign targetEmail = (verifyEmail!user.email)!"">

    <#if verifyEmail??>
        <p class="poc-verify-copy">
            เราได้ส่งอีเมลสำหรับยืนยันไปยัง <strong>${verifyEmail}</strong> แล้ว กรุณาตรวจสอบกล่องจดหมายและกดลิงก์ยืนยันในอีเมล
        </p>
    <#else>
        <p class="poc-verify-copy">
            ระบบจะส่งอีเมลสำหรับยืนยันไปยัง <strong>${targetEmail}</strong> กรุณากดปุ่มด้านล่างเพื่อดำเนินการ
        </p>
    </#if>

    <#if isAppInitiatedAction??>
        <form id="kc-verify-email-form" action="${url.loginAction}" method="post">
            <div class="poc-verify-actions">
                <#if verifyEmail??>
                    <button id="poc-verify-send" class="poc-verify-button poc-verify-button-primary" type="submit">
                        ส่งอีเมลยืนยันอีกครั้ง
                    </button>
                <#else>
                    <button id="poc-verify-send" class="poc-verify-button poc-verify-button-primary" type="submit">
                        ส่งอีเมลยืนยัน
                    </button>
                </#if>
                <#if (client.baseUrl)?has_content>
                    <a id="poc-change-email" class="poc-verify-button poc-verify-button-secondary" href="${app.appUpdateEmailUrl()}">
                        เปลี่ยนอีเมล
                    </a>
                </#if>
                <button id="poc-verify-cancel" class="poc-verify-button poc-verify-button-secondary" type="submit" name="cancel-aia" value="true" formnovalidate>
                    ยกเลิก
                </button>
            </div>
        </form>
    <#else>
        <p class="poc-verify-copy poc-verify-copy-secondary">
            ยังไม่ได้รับอีเมลยืนยัน?
        </p>
        <div class="poc-verify-actions">
            <a id="poc-verify-resend" class="poc-verify-button poc-verify-button-primary" href="${url.loginAction}">
                ส่งอีเมลยืนยันอีกครั้ง
            </a>
            <#if (client.baseUrl)?has_content>
                <a id="poc-change-email" class="poc-verify-button poc-verify-button-secondary" href="${app.appUpdateEmailUrl()}">
                    เปลี่ยนอีเมล
                </a>
            </#if>
        </div>
    </#if>
</@verify.page>
