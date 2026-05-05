# ⚙️ LAB-01: เตรียม Repository & Environment

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-02 Backend →](LAB-02-BACKEND.md)

---

## 🎯 เป้าหมาย

- Fork repository และ clone ลงเครื่อง
- สร้างไฟล์ environment สำหรับ frontend/backend
- ติดตั้ง dependencies ทั้ง root/backend/frontend
- เรียนรู้โครงสร้าง repository จริงของ `booking-app-demo-2025`
- ตรวจสอบ workflow `.github/workflows/ci.yml`

---

## ขั้นตอนที่ 1: Fork & Clone Repository

### 1.1 Fork Repository

1. เปิด [https://github.com/surachai-p/booking-app-demo-2025](https://github.com/surachai-p/booking-app-demo-2025)
2. คลิก **Fork** (มุมขวาบน)
3. เลือก owner เป็น account ของคุณ
4. คลิก **Create fork**

### 1.2 Clone ลงเครื่อง

```bash
# แทนที่ YOUR_USERNAME ด้วย GitHub username ของคุณ
git clone https://github.com/YOUR_USERNAME/booking-app-demo-2025.git
cd booking-app-demo-2025
```

ตรวจสอบโครงสร้างไฟล์:

```bash
ls -la
find . -maxdepth 2 -type d | sort
```

---

## ขั้นตอนที่ 2: สร้าง Environment Files

### 2.1 Backend `.env`

```bash
cp backend/.env.example backend/.env
```

แก้ไขค่าใน `backend/.env` ให้ตรงกับเครื่องของคุณ เช่น:

```bash
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/booking_app?schema=public"
```

### 2.2 Frontend `.env`

```bash
cp frontend/.env.example frontend/.env
```

แก้ไขค่าใน `frontend/.env` ให้ชี้ไปยัง backend local:

```bash
VITE_API_URL=http://localhost:3000
```

---

## ขั้นตอนที่ 3: ติดตั้ง Dependencies

### 3.1 ติดตั้ง root dependencies

```bash
npm install
```

### 3.2 ติดตั้ง backend dependencies

```bash
cd backend
npm install
```

### 3.3 ติดตั้ง frontend dependencies

```bash
cd ../frontend
npm install
```

---

## ขั้นตอนที่ 4: เตรียม Backend ด้วย Docker Compose และ Prisma

```bash
cd backend

docker compose up -d

npx prisma generate
npx prisma migrate dev --name init
```

ถ้ารันสำเร็จ คุณจะเห็น backend ทำงานที่:

```bash
http://localhost:3000
```

---

## ขั้นตอนที่ 5: รัน Frontend

```bash
cd ../frontend
npm run dev
```

เปิดเบราว์เซอร์ที่:

```bash
http://localhost:5173
```

ตรวจสอบว่า frontend สามารถเรียก backend ได้ผ่าน `VITE_API_URL`.

---

## ขั้นตอนที่ 6: ตรวจสอบ workflow

เปิดไฟล์:

```bash
cat .github/workflows/ci.yml
```

แทนที่จะสร้าง workflow ใหม่ ให้ใช้ workflow ที่มีอยู่และเข้าใจขั้นตอน:

- ติดตั้ง backend dependencies
- รัน Docker Compose สำหรับ PostgreSQL
- สร้าง Prisma client
- รัน Prisma migration
- ติดตั้ง frontend dependencies
- Build frontend

---

## ขั้นตอนที่ 7: Deployment Options (Optional)

หากต้องการ deploy ต่อไปยัง Vercel/Render ให้ทำตามขั้นตอนใน `README.md` และเตรียม secrets ดังนี้:

- `VITE_API_URL`
- `RENDER_DATABASE_URL` (สำหรับ Render ถ้าใช้)
- `JWT_SECRET` (สำหรับ production)

> หมายเหตุ: เป้าหมายหลักของใบงานนี้คือให้เข้าใจ workflow และ deployment path ของ repository ที่มีอยู่จริง

---

## ✅ Checklist ก่อนไปต่อ

- [ ] Fork และ clone repository สำเร็จ
- [ ] สร้าง `backend/.env` และ `frontend/.env`
- [ ] ติดตั้ง dependencies ทั้ง root/backend/frontend
- [ ] backend รันได้ที่ `http://localhost:3000`
- [ ] frontend รันได้ที่ `http://localhost:5173`
- [ ] ตรวจสอบไฟล์ `.github/workflows/ci.yml`

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-02 Backend →](LAB-02-BACKEND.md)
