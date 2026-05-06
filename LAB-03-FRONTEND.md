# 🎨 LAB-03: Frontend — Setup, Build & Vercel

[← LAB-02 Backend](LAB-02-BACKEND.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)

---

## 🎯 เป้าหมาย

- ติดตั้ง frontend dependencies
- สร้าง `.env` สำหรับ frontend
- รัน frontend local
- สร้าง production build
- ตรวจสอบคำสั่ง deployment บน Vercel

---

## ขั้นตอนที่ 1: ติดตั้ง Frontend Dependencies

```bash
cd frontend
npm install
```

ใน repository นี้ frontend ใช้ React + Vite + Tailwind

---

## ขั้นตอนที่ 2: สร้างไฟล์ Environment

```bash
cp frontend/.env.example frontend/.env
```

แก้ไข `frontend/.env`:

```bash
VITE_API_URL=http://localhost:3000
```

---

## ขั้นตอนที่ 3: รัน Frontend Local

```bash
npm run dev
```

เปิดเบราว์เซอร์ที่:

```bash
http://localhost:5173
```

ตรวจสอบว่า:

- หน้า Login โหลดได้
- สามารถ login ด้วย `admin/admin123`
- เข้าถึงหน้า Admin Dashboard ได้

---

## ขั้นตอนที่ 4: สร้าง Production Build

```bash
npm run build
```

หาก build สำเร็จ แสดงว่า frontend พร้อมสำหรับ deploy

---

## ขั้นตอนที่ 5: รัน Lint

```bash
npm run lint
```

หมายเหตุ: repository นี้ไม่มี unit tests แบบ Vitest/Jest ใน frontend แต่ CI workflow จะตรวจสอบ build และการติดตั้ง dependencies

---

## ขั้นตอนที่ 6: ตรวจสอบการ Deploy บน Vercel

หลังจาก push ขึ้น GitHub และ workflow รันสำเร็จ:

1. ไปที่ Vercel Dashboard
2. ตรวจสอบ project `booking-app-demo-2025`
3. ดู **Deployments** เพื่อตรวจสอบว่า deployment ล่าสุดสำเร็จ
4. คลิกที่ deployment ล่าสุดเพื่อดู logs
5. ตรวจสอบ **Environment Variables** เพื่อดูว่า `VITE_API_URL` ตั้งค่าถูกต้อง
6. ทดสอบ frontend ที่ Vercel URL:
   - เปิดเบราว์เซอร์ไปที่ Vercel URL
   - ลอง login ด้วย `admin/admin123`
   - ตรวจสอบว่า API calls ไปยัง backend ทำงาน

---

## ขั้นตอนที่ 7: ตรวจสอบ CI Workflow สำหรับ Frontend

เปิดไฟล์ `.github/workflows/ci.yml` แล้วตรวจสอบ:

1. มีขั้นตอน build frontend หรือไม่?
2. มีการ deploy ไป Vercel หรือไม่?
3. Environment variables ถูกส่งไปยัง Vercel อย่างไร?

---

## ✅ Checklist

- [ ] frontend dependencies ติดตั้งแล้ว
- [ ] frontend รันได้ที่ `http://localhost:5173`
- [ ] `frontend/.env` ถูกตั้งค่าเรียบร้อย
- [ ] build สำเร็จด้วย `npm run build`
- [ ] lint ผ่าน
- [ ] เข้าใจการตั้งค่า Vercel สำหรับ frontend
- [ ] ตรวจสอบ frontend deployment บน Vercel สำเร็จ

[← LAB-02 Backend](LAB-02-BACKEND.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)
