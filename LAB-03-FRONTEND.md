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

หากต้องการ deploy:

1. เชื่อมต่อ repository กับ Vercel
2. ตั้งค่า `Root Directory` เป็น `frontend`
3. ตั้งค่า build command เป็น `npm run build`
4. ตั้งค่า output directory เป็น `dist`
5. เพิ่ม environment variable:

```bash
VITE_API_URL=https://your-backend.onrender.com
```

---

## ✅ Checklist

- [ ] frontend dependencies ติดตั้งแล้ว
- [ ] frontend รันได้ที่ `http://localhost:5173`
- [ ] `frontend/.env` ถูกตั้งค่าเรียบร้อย
- [ ] build สำเร็จด้วย `npm run build`
- [ ] lint ผ่าน
- [ ] เข้าใจการตั้งค่า Vercel สำหรับ frontend

[← LAB-02 Backend](LAB-02-BACKEND.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)
