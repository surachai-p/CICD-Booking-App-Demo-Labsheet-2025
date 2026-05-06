# 🔒 LAB-04: Security Review & Deployment Hardening

[← LAB-03 Frontend](LAB-03-FRONTEND.md) | [ถัดไป: LAB-ASSIGNMENT →](LAB-ASSIGNMENT.md)

---

## 🎯 เป้าหมาย

- ตรวจสอบความปลอดภัยของ environment
- ตรวจสอบ dependency vulnerabilities
- เข้าใจความเสี่ยงของ self-hosted runner
- เตรียม deployment environment ให้ปลอดภัย

---

## ขั้นตอนที่ 1: ตรวจสอบ Dependencies

### 1.1 สแกน vulnerability ใน root

```bash
npm audit --audit-level=moderate
```

### 1.2 สแกน vulnerability ใน backend

```bash
cd backend
npm audit --audit-level=moderate
```

### 1.3 สแกน vulnerability ใน frontend

```bash
cd ../frontend
npm audit --audit-level=moderate
```

---

## ขั้นตอนที่ 2: ตรวจสอบ Environment

### 2.1 backend `.env`

เปิดไฟล์ `backend/.env` และตรวจสอบว่า:

- `DATABASE_URL` ไม่ใช้ค่า default ที่เป็นสาธารณะ
- ไม่มีข้อมูลลับอยู่ใน repository
- ใส่ค่า `JWT_SECRET` ที่แข็งแกร่งสำหรับ production

### 2.2 frontend `.env`

เปิดไฟล์ `frontend/.env` และตรวจสอบว่า:

- `VITE_API_URL` ชี้ไปยัง backend ที่ถูกต้อง
- ไม่มี API keys หรือ secrets ที่กระจายเข้าสู่ client

### 2.3 GitHub Secrets

ตรวจสอบ Secrets ใน GitHub repository:

- `VITE_API_URL`
- `JWT_SECRET` (ถ้าใช้สำหรับ production)
- `RENDER_DATABASE_URL` หรือ secret ของ Render

---

## ขั้นตอนที่ 3: ตรวจสอบ Security ของ Backend

เปิดไฟล์ `backend/server.js` แล้วอ่าน:

- การตั้งค่า CORS
- JWT authentication flow
- การเชื่อมต่อ PostgreSQL

สรุปความปลอดภัยที่ควรมีในระบบ:

- `CORS` ต้องยอมรับเฉพาะ frontend ที่เชื่อถือได้
- `JWT_SECRET` ต้องไม่ใช่ค่าสาธารณะ
- `DATABASE_URL` ต้องเก็บเป็น secret

---

## ขั้นตอนที่ 4: Self-hosted Runner Security

### 4.1 ข้อควรพิจารณา

- runner ต้องมีการอัปเดตระบบปฏิบัติการ
- pipeline อาจรัน Docker Compose ได้ ดังนั้นต้องกำหนดสิทธิ์
- อย่าให้ access token หรือ secrets หลุดใน logs

### 4.2 ตรวจสอบ workflow

เปิด `.github/workflows/ci.yml` แล้วดูว่า:

- runner เป็น `self-hosted`
- มีคำสั่งรัน Docker Compose หรือไม่
- มีคำสั่งรัน migration หรือ install dependencies อย่างชัดเจน

---

## ขั้นตอนที่ 5: ทดสอบ UI/UX ด้วย Robot Framework (Optional)

หากต้องการทำ automation test เพิ่มเติม:

```bash
pip install robotframework seleniumlibrary
robot tests/robot/hotel_booking_test.robot
```

Robot script นี้จะทดสอบ:

- หน้า Login
- การเข้าสู่ระบบด้วย admin
- การป้องกัน protected route
- การ logout

---

## ขั้นตอนที่ 6: ตรวจสอบ Security บน Production

### 6.1 ทดสอบ Backend API Security บน Render

```bash
# ทดสอบ CORS
curl -H "Origin: https://your-vercel-app.vercel.app" \
     https://your-backend.onrender.com/api/rooms

# ทดสอบ JWT authentication
curl https://your-backend.onrender.com/api/bookings \
     -H "Authorization: Bearer invalid-token"

# ทดสอบ rate limiting
for i in {1..10}; do
  curl https://your-backend.onrender.com/api/health
done
```

### 6.2 ทดสอบ Frontend Security บน Vercel

เปิดเบราว์เซอร์ไปที่ Vercel URL แล้วตรวจสอบ:

- HTTPS ทำงาน
- ไม่มี mixed content warnings
- API calls ไปยัง backend ทำงานผ่าน HTTPS
- ไม่มี sensitive data ใน browser console

### 6.3 ตรวจสอบ Environment Variables

- Vercel Dashboard → Project Settings → Environment Variables
- Render Dashboard → Service Settings → Environment
- ตรวจสอบว่าไม่มี secrets ถูก expose ใน frontend

---

## ✅ Checklist

- [ ] ทำ dependency scan ทั้ง root/backend/frontend
- [ ] ตรวจสอบ `.env` ว่าไม่มี secret ใน repository
- [ ] เข้าใจความเสี่ยงของ self-hosted runner
- [ ] ตรวจสอบ `.github/workflows/ci.yml` และ security flow
- [ ] รู้วิธีเพิ่ม secrets ใน GitHub
- [ ] ทดสอบ security บน production deployment

[← LAB-03 Frontend](LAB-03-FRONTEND.md) | [ถัดไป: LAB-ASSIGNMENT →](LAB-ASSIGNMENT.md)
