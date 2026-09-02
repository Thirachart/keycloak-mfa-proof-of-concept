# Production Readiness Checklist

Findings from an independent architecture/security review of the current PoC, verified against actual source
(not assumptions). Overall verdict: **core design is sound** (token generation, hashing, revocation-on-credential-change,
SPI/Event-Listener architecture, `kc_action` allowlisting all follow Keycloak best practice) — what remains is
**configuration hardening**, not redesign. No Critical/High vulnerabilities were confirmed; two items below are
real gaps worth treating as launch-blocking, the rest are conditional or already acceptable.

Legend:
- **ต้องแก้ (Must-fix / P0)** — real exploit path or explicit anti-pattern, cheap to fix, no reason to defer.
- **ควรแก้ (Should-fix / P1)** — real risk but conditional on deployment topology, or worth doing for robustness/maintainability.
- **แก้ทีหลังได้ (Can defer / P2)** — polish, defense-in-depth, or low-impact.
- **ไม่ต้องแก้ (No action needed)** — reviewed and confirmed acceptable as-is; flagged so it isn't second-guessed later.

---

## P0 — ต้องแก้ก่อนขึ้น Production

### 1. เปิด Keycloak realm brute-force protection
- **ปัญหา**: [`keycloak/realm/poc-realm.json`](../keycloak/realm/poc-realm.json) ไม่มี `bruteForceProtected` เลยทั้งไฟล์ → default คือ `false` → หน้า login (username/password) ไม่มี lockout ใด ๆ ทั้งสิ้น
- **ความเสี่ยง**: brute-force / credential-stuffing ยิงรหัสผ่านได้ไม่จำกัดจำนวนครั้ง เป็นช่องโหว่มาตรฐานที่ scanner/pentest จะเจอทันที
- **แก้อย่างไร**: ตั้ง `bruteForceProtected: true` ใน realm config พร้อม tune `failureFactor`, `waitIncrementSeconds`, `maxFailureWaitSeconds`, `permanentLockout` ตามนโยบายองค์กร
- **ผลกระทบถ้าไม่แก้**: จริง ไม่ใช่ทฤษฎี — ควรทำก่อนเปิดให้ user จริงใช้งานเสมอ

### 2. เลิกใช้ `start-dev`, แก้ hostname strict mode
- **ปัญหา**: [`docker-compose.yml`](../docker-compose.yml) รัน Keycloak ด้วย `start-dev` และตั้ง `KC_HOSTNAME_STRICT: "false"` — ทั้งสองค่านี้ Keycloak เอกสารระบุชัดว่าห้ามใช้ใน production
- **ความเสี่ยง**: `start-dev` ปิดการ optimize/บาง hardening default, hostname ไม่ strict เปิดช่อง host-header / redirect manipulation
- **แก้อย่างไร**: build image แบบ `kc.sh build` แล้ว `start --optimized`, ตั้ง `KC_HOSTNAME` เป็น domain จริงของ production และเปิด `KC_HOSTNAME_STRICT: "true"`

---

## P1 — ควรแก้ (ขึ้นอยู่กับ network topology จริง หรือเพื่อความทนทาน/บำรุงรักษา)

> จุดกลุ่มนี้ไม่ใช่ "ข้ามไม่ได้เด็ดขาด" แต่ความเสี่ยงจริงขึ้นกับว่า production topology รับประกันอะไรได้บ้าง — ถ้าไม่มั่นใจ ให้ถือเป็น P0

### 3. ตั้งค่า reverse-proxy trust chain ให้ Keycloak เชื่อ header ที่ถูกต้อง
- **ปัญหา**: ไม่มี `KC_PROXY_HEADERS`/`--proxy-headers` ตั้งไว้เลยทั้งที่ Keycloak วิ่งหลัง Kong → oauth2-proxy ([`docker-compose.yml`](../docker-compose.yml), [`kong/kong.yml`](../kong/kong.yml))
- **ผลที่ตามมาในโค้ดจริง**: [`TrustedDeviceSupport.java`](../keycloak/extension/src/main/java/poc/keycloak/TrustedDeviceSupport.java) ตัดสิน `Secure` cookie flag จาก scheme ที่ Keycloak เห็นเอง — ถ้าไม่ trust `X-Forwarded-Proto` จาก proxy chain, Keycloak จะเห็นเป็น `http` แม้ผู้ใช้เข้าจริงผ่าน HTTPS → cookie ไม่ได้ `Secure` flag ทั้งที่ควรมี
- **เงื่อนไขที่พอข้ามได้ชั่วคราว**: ถ้า production บังคับ HTTPS-only ทั้งระบบจริง (มี HSTS, force redirect, ไม่มี plaintext listener เปิดเลย) risk จากจุดนี้จะต่ำ เพราะไม่มีช่องทางให้ browser ส่ง cookie แบบ cleartext อยู่แล้ว
- **แก้อย่างไร**: ตั้ง `KC_PROXY_HEADERS=xforwarded` (หรือค่าที่ตรงกับ Kong) และปิด direct network access ไป Keycloak/oauth2-proxy ให้เข้าถึงได้ผ่าน Kong เท่านั้น

### 4. เปิด `cookie_secure=true` แบบ environment-conditional ใน oauth2-proxy
- **ปัญหา**: [`oauth2-proxy/oauth2-proxy.cfg`](../oauth2-proxy/oauth2-proxy.cfg) hardcode `cookie_secure = false` (ใช้ได้สำหรับ local HTTP-only PoC เท่านั้น)
- **แก้อย่างไร**: ทำ config เป็น environment-conditional หรือแยกไฟล์ config ต่อ environment แล้วตั้ง `true` สำหรับ production

### 5. เพิ่ม trusted-proxy allowlist ให้ Kong/oauth2-proxy
- **ปัญหา**: `reverse_proxy = true` ใน oauth2-proxy ไม่มี trusted-proxy IP/count restriction คู่กัน; Kong ก็ไม่มี TLS termination/X-Forwarded handling หรือ trusted-proxy list
- **ความเสี่ยง**: ถ้า network ไม่ได้ isolate ให้เข้าถึง backend ได้เฉพาะผ่าน Kong เท่านั้น จะเปิดช่อง header spoofing (ปลอม `X-Forwarded-Proto`/`X-Forwarded-For`)
- **แก้อย่างไร**: จำกัด network access ระดับ infra (Keycloak/oauth2-proxy ไม่ expose ตรงสู่ internet) + ตั้ง trusted-proxy list ชัดเจนใน config

### 6. Verify ตัวเลข attempt-limit / resend-cooldown ของ Email OTP
- **สถานะปัจจุบัน**: third-party plugin (`keycloak-2fa-email-authenticator`) มี attempt-limit และ resend-cooldown ของตัวเองอยู่แล้ว (ยืนยันจาก message key `email-authenticator-too-many-attempts`, `email-authenticator-resend-cooldown` ใน theme และการทดสอบใน [`docs/test-cases.md`](test-cases.md)) — **ไม่ได้ขาดกลไก** แค่ยังไม่มีใครยืนยันตัวเลขจริง (code TTL, max attempts, cooldown วินาที) ว่าเหมาะสมกับนโยบายความปลอดภัยที่ต้องการหรือไม่
- **แก้อย่างไร**: ตรวจ default ของ plugin แล้วปรับ (ถ้าปรับได้) ให้ตรงนโยบายองค์กร ไม่ต้องสร้างกลไกใหม่

### 7. Bake User Profile attribute protection เข้า realm import (defense-in-depth)
- **สถานะปัจจุบัน**: `unmanagedAttributePolicy=ADMIN_EDIT` ถูกตั้งผ่าน [`scripts/configure-auth-flows.ps1`](../scripts/configure-auth-flows.ps1) เท่านั้น ไม่ได้อยู่ใน [`poc-realm.json`](../keycloak/realm/poc-realm.json) ที่ import ตอน container start
- **ทำไมไม่ใช่ P0**: ยืนยันจาก Keycloak 26.x official docs ว่า default ของ `unmanagedAttributePolicy` เมื่อไม่ตั้งค่าคือ `DISABLED` ซึ่งปลอดภัยอยู่แล้ว (attribute ที่ไม่ได้ declare จะถูกเพิกเฉยในทุก self-service context โดยอัตโนมัติ) แปลว่า `poc_mfa_trusted_device`/`poc_mfa_trusted_until` ไม่ได้ถูกเปิดให้ user แก้เองได้แม้ไม่รัน script
- **แก้อย่างไร**: ย้าย policy setting เข้า realm export/User Profile declarative config ให้เป็นส่วนหนึ่งของ IaC เพื่อความชัดเจนและกันคนมาเปลี่ยน policy ระดับ realm ทีหลังโดยไม่รู้ตัว

### 8. Rotate secrets ทั้งหมดที่เป็นค่า default ใน docker-compose
- **ปัญหา**: client secret, DB password, SMTP credential ที่เห็นใน [`docker-compose.yml`](../docker-compose.yml) เป็นค่า PoC/dev
- **แก้อย่างไร**: ใช้ secret manager หรือ environment injection ที่เหมาะสมกับ production infra ก่อน deploy จริง

---

## P2 — แก้ทีหลังได้ (polish / defense-in-depth)

### 9. Scope `poc_password_aia_state` cookie ให้แคบลง
- ปัจจุบัน production ใช้ `Domain=.pfas.pattaya.go.th` (wildcard subdomain) — ถ้ามี subdomain อื่นใต้โดเมนเดียวกันที่อาจถูก compromise (XSS) จะ "cookie toss" ตั้งค่านี้เป็น `submitted` เพื่อหลอกโชว์ข้อความสำเร็จปลอมได้ — impact แค่ cosmetic (ไม่กระทบ authentication/authorization state จริง) แนะนำ scope `Domain`/`Path` แคบลงถ้าทำได้ง่าย ไม่จำเป็นต้องรีบ

### 10. เพิ่ม self-service "sign out of trusted devices" ใน Account Console
- Defense-in-depth สำหรับกรณี device ถูก compromise (malware, shared browser) — ตอนนี้พึ่ง expiry + revoke-on-credential-change ซึ่งเพียงพอในระดับ acceptable-risk อยู่แล้ว

### 11. พิจารณา bind trust cookie กับ secondary signal (เช่น User-Agent hash)
- Marginal benefit เท่านั้น ไม่จำเป็นสำหรับ scale ปัจจุบัน

### 12. ตรวจสอบว่า `template/` เป็น duplicate ของ `keycloak/themes/` ที่อาจ drift กันหรือไม่
- ความเสี่ยงด้าน maintainability ไม่ใช่ security — ตรวจสอบเมื่อมีเวลา

---

## ไม่ต้องแก้ (ตรวจแล้วว่าของเดิมเหมาะสม — อย่า over-engineer)

- **`poc_password_aia_state` cookie ไม่ HttpOnly** — ถูกต้องแล้ว คุกกี้นี้ต้อง JS อ่านได้โดยดีไซน์ (ไม่มี token/password ปนอยู่ เป็นแค่ UX flag)
- **ไม่ต้องสร้าง server-side callback bridge สำหรับ `kc_action_status`** — เป็นแค่ UX cosmetic ไม่ใช่ security state, การสร้าง service เพิ่มเพื่อแก้ปัญหานี้คือ over-engineering เทียบกับความเสี่ยงจริง
- **Trusted Device เก็บใน Keycloak User Attribute** — เหมาะสมสำหรับ scale ปัจจุบัน (cap 10 records/user) ไม่ต้องย้ายไป dedicated database เว้นแต่ต้องการ query ข้าม user จำนวนมากหรือ compliance ต้องการ structured audit query ซึ่งยังไม่มีเหตุผลนั้นในระบบนี้
- **Reset Password ใช้ Keycloak native Reset Credentials Flow + `UPDATE_PASSWORD` Required Action** — เป็นแนวทางมาตรฐานของ Keycloak อยู่แล้ว ไม่ต้องแตะ
- **Trusted device cap eviction โดย soonest-expiry แทน oldest-created** — เป็น design choice เล็กน้อย ไม่ใช่ security bug

---

## สรุป

ถ้าจะขึ้น production จริงสำหรับ internet-facing user ทั่วไป **อย่างน้อยที่สุดต้องทำ P0 ทั้ง 2 ข้อ** (brute-force protection, เลิก start-dev) เพราะเป็นช่องโหว่จริงและแก้ง่ายมาก ไม่มีเหตุผลจะข้าม ส่วน P1 ข้อ 3-5 (reverse-proxy chain) ให้ประเมินตาม network topology จริงที่จะ deploy — ถ้าไม่มั่นใจว่า HTTPS-only ทั้งระบบและ backend ปิดจาก public internet จริง ให้ยกขึ้นเป็น P0 เช่นกัน
