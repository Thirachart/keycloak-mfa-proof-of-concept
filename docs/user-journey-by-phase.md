# User Journey by Phase

เอกสารนี้อธิบายสิ่งที่ผู้ใช้งานจะพบเมื่อระบบอยู่ใน Phase 1 และ Phase 2 โดยเน้นมุมมองของผู้ใช้งาน ไม่ใช่ขั้นตอนการตั้งค่าของผู้ดูแลระบบ

## ภาพรวม

| ความสามารถ | Phase 1 | Phase 2 |
| --- | --- | --- |
| Login ด้วย Username/Password | ได้ | ได้ |
| เข้าใช้งานได้ทั้งที่ Email ยังไม่ Verify | ได้ | ไม่ได้ |
| ปุ่ม Verify Email ใน Application | มี เมื่อ Email ยังไม่ Verify | มี แต่ระบบบังคับ Verify ก่อนเข้าใช้งานหากยังไม่ Verify |
| Email OTP ตอน Login | ไม่บังคับ | บังคับเมื่อ Browser ยังไม่ Trusted หรือ Trust หมดอายุ |
| หน้าเลือกวิธี MFA | ไม่มี | มีเฉพาะเมื่อ Browser ยังไม่ Trusted หรือ Trust หมดอายุ |
| วิธี MFA ที่เปิดใช้งานตอนนี้ | - | Email OTP |
| Password หมดอายุ | ไม่บังคับ | 180 วัน สำหรับ Local Keycloak Password |
| External IdP Login | ได้ | ได้ โดย MFA หลังกลับ Keycloak ขึ้นกับ `require_mfa_after_broker` ของแต่ละ IdP |

---

# Phase 1 — Email Verification แบบสมัครใจ

เป้าหมายของ Phase 1 คือให้ผู้ใช้งานสามารถเข้าใช้ระบบเดิมได้ก่อน โดยยังไม่บังคับ Email Verification, MFA หรือ Password Expiration

## 1. Login ปกติ

ผู้ใช้พบหน้า Login ของ Keycloak และกรอก:

```text
Username
Password
[ Sign in ]
```

เมื่อ Username/Password ถูกต้อง ผู้ใช้สามารถเข้า Application ได้ทันที

```text
Username + Password
        ↓
     Success
        ↓
   Application
```

Email ยังไม่จำเป็นต้อง Verified ใน Phase 1

## 2. ผู้ใช้มี Email แต่ยังไม่ Verify

เมื่อเข้า Application ผู้ใช้จะเห็นสถานะประมาณ:

```text
Email verification
NOT VERIFIED

[ Verify email ]
```

ผู้ใช้ยังใช้งาน Application ได้ตามปกติ และสามารถเลือกกด `Verify email` เมื่อพร้อม

เมื่อกดปุ่ม ระบบจะส่งผู้ใช้ไปยัง Keycloak Application-Initiated Action `VERIFY_EMAIL`

```text
Application
    ↓
Verify email
    ↓
Keycloak
    ↓
ส่ง Verification Email
    ↓
ผู้ใช้กด Link ใน Email
    ↓
Email Verified
```

หลัง Verify สำเร็จ ระบบเก็บสถานะ `email_verified=true` และ PoC เก็บ `email_verified_at` จากเหตุการณ์ Verify Email ที่ Keycloak สังเกตได้

## 3. ผู้ใช้ไม่มี Email

Application จะแสดง:

```text
Email verification
NO EMAIL

[ Add email first ]
```

ปุ่มจะพาผู้ใช้ไปยัง Keycloak Account Console เพื่อเพิ่ม Email ก่อน

## 4. ผู้ใช้ Verify Email แล้ว

Application จะแสดง:

```text
Email verification
VERIFIED
Verified at: <date/time>
```

ปุ่ม Verify Email จะไม่แสดงอีก

## 5. Password ใน Phase 1

Phase 1 **ไม่เปิด policy บังคับเปลี่ยน Password ทุก 180 วัน**

ดังนั้นการสลับระบบมา Phase 1 จะไม่ใช้ `forceExpiredPasswordChange(180)`

## 6. MFA ใน Phase 1

Phase 1 ไม่บังคับ Email OTP และไม่แสดงหน้าเลือกวิธี MFA

---

# Phase 2 — Verified Email + MFA + Password Expiration

เป้าหมายของ Phase 2 คือยกระดับ Authentication Policy โดยบังคับ Email Verification, MFA และ Password Expiration สำหรับ Local Keycloak Password

> MFA trust รองรับ 2 mode: `trustedDeviceEnabled=true` จะ trust แยกตาม Browser/Device; `trustedDeviceEnabled=false` จะ trust ระดับ User Account ทำให้ทุก device ข้าม OTP ได้ภายใน `TrustDays` (default 30 วัน) หลังมี OTP สำเร็จอย่างน้อยหนึ่งครั้ง

## 1. Login ด้วย Local Account

ผู้ใช้เริ่มจาก:

```text
Username
Password
[ Sign in ]
```

หลัง Username/Password ถูกต้อง Keycloak จะตรวจ Required Actions และ Authentication Policy ที่เกี่ยวข้อง

Journey โดยทั่วไปเป็น:

```text
Username + Password
        ↓
ตรวจ Password Expiration
        ↓
ตรวจ Email Verification
        ↓
มี Trusted Browser ที่ยังไม่หมดอายุ?
        │
        ├─ Yes → ข้าม MFA → Application
        │
        └─ No
             ↓
        Choose verification method
             ↓
         Email OTP
             ↓
      สร้าง Trusted Browser 30 วัน
             ↓
        Application
```

ลำดับหน้าจอ Required Action กับ Authentication Flow บางส่วนอาจขึ้นกับ lifecycle ของ Keycloak แต่เงื่อนไขทั้งหมดต้องสำเร็จก่อนเข้า Application

## 2. Email ยังไม่ Verify

Phase 2 ไม่อนุญาตให้ผู้ใช้ที่ Email ยังไม่ Verified เข้า Application จนกว่าจะ Verify สำเร็จ

ผู้ใช้จะถูก Keycloak บังคับเข้าสู่ Verify Email flow:

```text
Email not verified
      ↓
Keycloak sends verification email
      ↓
User opens verification link
      ↓
Email verified
      ↓
Continue authentication
```

ต่างจาก Phase 1 ตรงที่ Phase 1 ให้ผู้ใช้เลือก Verify ภายหลังได้ แต่ Phase 2 ถือว่า Email Verification เป็นเงื่อนไขของการ Login

## 3. Password มีอายุครบ 180 วัน

Policy นี้ใช้เฉพาะ Phase 2:

```text
forceExpiredPasswordChange(180)
```

ถ้า Local Keycloak Password หมดอายุ Keycloak จะเพิ่ม `UPDATE_PASSWORD` required action และผู้ใช้ต้องเปลี่ยน Password ก่อน Login สำเร็จ

```text
Password expired
      ↓
Update Password
      ↓
New Password
Confirm Password
      ↓
Continue authentication
```

Keycloak ประเมิน password-expiration trigger ระหว่าง authentication และ Update Password เป็น Required Action ที่ต้องเสร็จก่อน Login สมบูรณ์

### External IdP

Policy 180 วันนี้ใช้กับ **Local Password ของ realm `poc`** เท่านั้น

ถ้าผู้ใช้ Login ผ่าน External IdP ระบบภายนอกเป็นผู้รับผิดชอบ Password ของตนเอง ดังนั้น Keycloak `poc` ไม่ควรบังคับอายุ Password ของ External IdP

## 4. หน้าเลือก MFA

เมื่อถึงขั้น MFA ผู้ใช้จะเห็นหน้าแยกชัดเจน:

```text
Verify your identity

● Email OTP
  Send a one-time code to your email

○ Authenticator App
  Not available yet

○ Passkey / WebAuthn
  Not available yet

[ Continue ]
```

ตอนนี้เปิดใช้งานจริงเฉพาะ `Email OTP`

Authenticator App และ Passkey แสดงไว้เพื่อให้เห็นโครงสร้างที่จะรองรับในอนาคต แต่ยังเลือกไม่ได้

## 5. Email OTP

หลังเลือก Email OTP:

```text
Choose Email OTP
      ↓
Keycloak sends OTP email
      ↓
Enter OTP
      ↓
OTP valid
      ↓
Continue
```

เมื่อ Email OTP สำเร็จ ระบบจะสร้าง Trusted Browser ให้อัตโนมัติเป็นเวลา 30 วัน โดยไม่มี checkbox ให้ผู้ใช้เลือก

```text
Email OTP success
      ↓
สร้าง random device token ใน Browser cookie
      ↓
เก็บเฉพาะ hash + expiry เป็น server-side trusted-device record
      ↓
Trust 30 days
```

Login ที่ผ่าน OTP จะมี:

```text
mfa_method=email
```

Login ครั้งถัดไปจาก Browser เดิมที่ Trust ยังไม่หมดอายุจะข้าม MFA และมี:

```text
mfa_method=trusted_device
```

Application จะแสดง `Email OTP` หรือ `Trusted browser (OTP skipped)` ตามวิธีที่ใช้ใน session นั้น

## 6. Login ผ่าน External IdP

Phase 2 รองรับการกำหนด MFA หลัง External IdP แยกเป็นราย IdP ด้วย config:

```text
require_mfa_after_broker=true | false
```

เมื่อ `require_mfa_after_broker=true` จะใช้ Trusted Browser policy เดียวกับ Local Login:

```text
Application
    ↓
Keycloak
    ↓
External Identity Provider
    ↓
External authentication succeeds
    ↓
Return to Keycloak
    ↓
Phase 2 Post Broker Login
    ↓
Trusted Browser valid?
    ├─ Yes → Application
    └─ No  → Choose verification method → Email OTP
                                  ↓
                         Trust browser 30 days
                                  ↓
                             Application
```

เมื่อ `require_mfa_after_broker=false`:

```text
Application
    ↓
Keycloak
    ↓
External Identity Provider
    ↓
External authentication succeeds
    ↓
Return to Keycloak
    ↓
Application
```

ดังนั้น IdP ที่องค์กรเชื่อถือ MFA ของต้นทางอยู่แล้วสามารถตั้งค่าไม่ให้ Keycloak ถาม OTP ซ้ำได้ ส่วน IdP ที่ยังต้องการ MFA เพิ่มให้ตั้ง `require_mfa_after_broker=true` โดย Local Login ใน Phase 2 ยังคงบังคับ MFA เสมอ

---

# เปรียบเทียบ Journey แบบสั้น

## Phase 1

```text
Login
  ↓
Username + Password
  ↓
Application
  ↓
Email ยังไม่ Verified ก็ใช้งานได้
  ↓
ผู้ใช้เลือกกด Verify Email ภายหลังได้
```

## Phase 2

```text
Login
  ↓
Username + Password
  ↓
Password หมดอายุ? ── Yes ──> Change Password
  ↓ No
Email Verified? ───── No ───> Verify Email
  ↓ Yes
Trusted Browser valid? ─ Yes ─> Application
  ↓ No
Choose MFA
  ↓
Email OTP
  ↓
Trust browser 30 days
  ↓
Application
```

---

# สิ่งที่เปลี่ยนเมื่อเปิด Phase 2

เมื่อผู้ดูแลระบบสลับจาก Phase 1 ไป Phase 2 ระบบจะเปิดพร้อมกันดังนี้:

1. `verifyEmail=true`
2. ใช้ Browser Flow `poc-phase2-browser-v3`
3. ตรวจ Server-side Trusted Browser ก่อน MFA
4. ถ้าไม่ Trusted ให้เปิด MFA Method Selector และบังคับ Email OTP
5. หลัง OTP สำเร็จสร้าง Trusted Browser อัตโนมัติ 30 วัน
6. External IdP ใช้ Phase 2 Post Broker Login MFA เฉพาะเมื่อ IdP นั้นตั้ง `require_mfa_after_broker=true` และใช้ Trusted Browser policy เดียวกัน
7. เปิด Password Expiration 180 วันสำหรับ Local Keycloak Password
8. Logout existing sessions เพื่อให้ policy ใหม่มีผลกับการ Login ครั้งถัดไป

เมื่อย้อนกลับ Phase 1 ระบบจะปิด Password Expiration 180 วัน พร้อมกับ Email OTP/mandatory Email Verification ของ Phase 2
