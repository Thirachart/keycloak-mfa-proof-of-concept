<#ftl output_format="plainText">
<#assign displayName = user.username>
<#if user.firstName?? && user.firstName?has_content>
  <#assign displayName = user.firstName>
</#if>
ยืนยันอีเมลของคุณ

เรียน คุณ${displayName}

ท่านได้ทำการลงทะเบียนบัญชีผู้ใช้งานกับระบบการเงินและบัญชีเมืองพัทยา (PFAS) กรุณาเปิดลิงก์ด้านล่างเพื่อยืนยันความเป็นเจ้าของอีเมลนี้ และเปิดใช้งานบัญชีของท่านให้สมบูรณ์

${link}

ลิงก์นี้จะหมดอายุภายใน ${linkExpirationFormatter(linkExpiration)}

หากท่านไม่ได้เป็นผู้ทำรายการนี้ กรุณาเพิกเฉยต่ออีเมลฉบับนี้ ท่านไม่จำเป็นต้องดำเนินการใดๆ เพิ่มเติม

© เมืองพัทยา · ระบบการเงินและบัญชีเมืองพัทยา (PFAS)