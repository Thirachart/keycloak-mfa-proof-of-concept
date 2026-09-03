<#ftl output_format="HTML" auto_esc=true>
<#assign displayName = user.username>
<#if user.firstName?? && user.firstName?has_content>
  <#assign displayName = user.firstName>
</#if>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f3f1; padding:48px 24px;">
<tr><td align="center">
<table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px; width:100%; background:#ffffff; border-radius:12px; overflow:hidden; font-family:'Sarabun','Noto Sans Thai','Tahoma',sans-serif;">
<tr><td style="padding:40px 48px 32px 48px;">

<table role="presentation" cellpadding="0" cellspacing="0"><tr>
<td style="vertical-align:middle;">
<div style="font-size:15px; font-weight:700; color:#1c1917;">PFAS</div>
<div style="font-size:12px; color:#78716c;">ระบบการเงินและบัญชีเมืองพัทยา</div>
</td>
</tr></table>

<div style="height:1px; background:#e7e5e4; margin:28px 0;"></div>

<h1 style="margin:0 0 16px 0; font-size:22px; font-weight:700; color:#1c1917; font-family:'Sarabun','Noto Sans Thai','Tahoma',sans-serif;">ตั้งรหัสผ่านใหม่</h1>

<p style="margin:0; font-size:15px; line-height:1.75; color:#44403c;">
เรียน คุณ${displayName}<br />
เราได้รับคำขอให้ตั้งรหัสผ่านใหม่สำหรับบัญชีระบบการเงินและบัญชีเมืองพัทยา (PFAS) ของท่าน กรุณากดปุ่มด้านล่างเพื่อกำหนดรหัสผ่านใหม่
</p>

<table role="presentation" cellpadding="0" cellspacing="0" style="margin:28px auto;"><tr>
<td style="border-radius:8px; background:#f26d1f;">
<a href="${link}" target="_blank" style="display:inline-block; padding:13px 40px; font-size:15px; font-weight:700; color:#ffffff; text-decoration:none; font-family:'Sarabun','Noto Sans Thai','Tahoma',sans-serif;">ตั้งรหัสผ่านใหม่</a>
</td>
</tr></table>

<p style="margin:0 0 16px 0; font-size:13px; color:#78716c; text-align:center;">ลิงก์นี้จะหมดอายุภายใน ${linkExpirationFormatter(linkExpiration)}</p>

<p style="margin:0 0 8px 0; font-size:13px; line-height:1.6; color:#78716c;">หากปุ่มด้านบนไม่สามารถใช้งานได้ กรุณาคัดลอกลิงก์ด้านล่างนี้ไปวางในเบราว์เซอร์ของท่าน</p>
<div style="background:#f5f5f4; border:1px solid #e7e5e4; border-radius:6px; padding:10px 14px; font-size:12px; color:#57534e; word-break:break-all;">${link}</div>

<div style="height:1px; background:#e7e5e4; margin:28px 0;"></div>

<p style="margin:0; font-size:12px; line-height:1.7; color:#a8a29e;">หากท่านไม่ได้เป็นผู้ขอตั้งรหัสผ่านใหม่ กรุณาเพิกเฉยต่ออีเมลฉบับนี้ รหัสผ่านเดิมของท่านจะยังคงใช้งานได้จนกว่าจะมีการตั้งรหัสผ่านใหม่สำเร็จ</p>

</td></tr>
<tr><td style="background:#faf9f8; padding:20px 48px; text-align:center;">
<p style="margin:0; font-size:12px; color:#a8a29e;">&copy; เมืองพัทยา &middot; ระบบการเงินและบัญชีเมืองพัทยา (PFAS)</p>
</td></tr>
</table>

</td></tr>
</table>