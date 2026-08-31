<#ftl output_format="plainText">
<#assign displayName = user.username>
<#if user.firstName?? && user.firstName?has_content>
  <#assign displayName = user.firstName>
</#if>
ยืนยันอีเมลใหม่ - ระบบการเงินและบัญชีเมืองพัทยา (PFAS)

เรียน คุณ${displayName}

ท่านได้ขอเปลี่ยนอีเมลสำหรับบัญชีระบบการเงินและบัญชีเมืองพัทยา (PFAS) เป็น ${newEmail}
กรุณาเปิดลิงก์ด้านล่างเพื่อยืนยันอีเมลใหม่ก่อนที่ระบบจะเปลี่ยนข้อมูลในบัญชี

${link}

ลิงก์นี้จะหมดอายุภายใน ${linkExpirationFormatter(linkExpiration)}

หากท่านไม่ได้เป็นผู้ขอเปลี่ยนอีเมล กรุณาเพิกเฉยต่ออีเมลฉบับนี้ อีเมลเดิมของบัญชีจะยังคงใช้งานตามเดิม
