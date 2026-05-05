# 🔧 LAB-02: Backend — Setup, Prisma & API Tests

[← LAB-01 Setup](LAB-01-SETUP.md) | [ถัดไป: LAB-03 Frontend →](LAB-03-FRONTEND.md)

---

## 🎯 เป้าหมาย

- ติดตั้ง backend dependencies
- เรียนรู้ Prisma + PostgreSQL
- รัน backend service
- ทดสอบ API ด้วย Newman
- ตรวจสอบ workflow CI ที่ใช้งาน backend

---

## ขั้นตอนที่ 1: ติดตั้ง Backend Dependencies

```bash
cd backend
npm install
```

นอกจากนี้ ให้ติดตั้ง dependencies บน root เพื่อใช้ Newman:

```bash
cd ..
npm install
```

---

## ขั้นตอนที่ 2: ตั้งค่า Database

### 2.1 สร้าง PostgreSQL ด้วย Docker Compose

```bash
cd backend
docker compose up -d
```

### 2.2 สร้าง Prisma client

```bash
npx prisma generate
```

### 2.3 รัน migration

```bash
npx prisma migrate dev --name init
```

> หากพบข้อความเกี่ยวกับ migration ให้ตอบ `y` เพื่อสร้าง migration ใหม่ตาม schema

---

## ขั้นตอนที่ 3: รัน Backend

```bash
npm run dev
```

ตรวจสอบ backend ว่าเปิดใช้งานได้:

```bash
curl http://localhost:3000/api/rooms
```

หรือเรียก endpoint ไม่ต้องใช้ token เช่น:

```bash
curl http://localhost:3000/api/rooms
```

---

## ขั้นตอนที่ 4: รัน Newman API Tests

จาก root repository:

```bash
cd ..
npx newman run newman/hotel-booking-collection.json   -e newman/hotel-booking-env.json   --env-var baseUrl=http://localhost:3000
```

### 4.1 คำอธิบาย

- `newman/hotel-booking-collection.json` คือชุด API tests ของระบบ
- `newman/hotel-booking-env.json` คือ environment template
- `--env-var baseUrl` ชี้ไปยัง backend local

### 4.2 ถ้าต้องการรายงาน HTML

```bash
npx newman run newman/hotel-booking-collection.json   -e newman/hotel-booking-env.json   --env-var baseUrl=http://localhost:3000   -r htmlextra
```

---

## ขั้นตอนที่ 5: ตรวจสอบ endpoint สำคัญ

เปิดไฟล์ `backend/server.js` และอ่าน route ที่มี:

- `POST /api/login`
- `GET /api/bookings`
- `POST /api/bookings`
- `PUT /api/bookings/:id`
- `DELETE /api/bookings/:id`

---

## ขั้นตอนที่ 6: ตรวจสอบ CI Workflow

เปิดไฟล์ `.github/workflows/ci.yml` แล้วตอบคำถาม:

1. Workflow นี้รันบน runner แบบใด?
2. มีคำสั่งใดบ้างที่เกี่ยวกับ Prisma?
3. frontend build ถูกสั่งให้รันอย่างไร?

---

## ✅ Checklist

- [ ] backend dependencies ติดตั้งแล้ว
- [ ] backend รันผ่านที่ `http://localhost:3000`
- [ ] Prisma client สร้างสำเร็จ
- [ ] migration รันผ่าน
- [ ] Newman API tests ผ่าน
- [ ] เข้าใจ `.github/workflows/ci.yml` ที่เกี่ยวข้องกับ backend

[← LAB-01 Setup](LAB-01-SETUP.md) | [ถัดไป: LAB-03 Frontend →](LAB-03-FRONTEND.md)
