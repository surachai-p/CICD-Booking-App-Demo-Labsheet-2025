# ⚙️ LAB-01: เตรียม Repository, Backend, Frontend และ Deployment

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)

---

## 🎯 เป้าหมาย

- Fork และ clone repository จาก GitHub
- สร้าง environment files สำหรับ backend และ frontend
- ติดตั้ง dependencies สำหรับ root, backend และ frontend
- รัน backend ด้วย Docker Compose และ Prisma
- ทดสอบ API ด้วย Newman
- รัน frontend local, สร้าง build และตรวจสอบ lint
- ตั้งค่า deployment สำหรับ Vercel และ Render
- ตั้งค่า GitHub Actions secrets และตรวจสอบ workflow

---

## ขั้นตอนที่ 1: Fork & Clone Repository

### 1.1 Fork Repository

1. เปิด: https://github.com/surachai-p/booking-app-demo-2025
2. คลิก **Fork** ด้านขวาบน
3. เลือก owner เป็นบัญชีของคุณ
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

แก้ไข `backend/.env` ให้ชี้ไปยังฐานข้อมูล local:

```bash
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/booking_app?schema=public"
```

### 2.2 Frontend `.env`

```bash
cp frontend/.env.example frontend/.env
```

แก้ไข `frontend/.env`:

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

## ขั้นตอนที่ 4: รัน Backend ด้วย Docker Compose และ Prisma

### 4.1 ตรวจสอบ Docker

```bash
docker --version
docker ps
```

### 4.2 รัน PostgreSQL ด้วย Docker Compose

```bash
cd backend
docker compose up -d
```

ตรวจสอบว่า container ทำงาน:

```bash
docker ps
```

ควรเห็น container `postgres` กำลังรัน ✅

### 4.3 สร้าง Prisma Client

```bash
npx prisma generate
```

### 4.4 รัน Database Migration

```bash
npx prisma migrate dev --name init
```

**หมายเหตุ:** ห้ามใช้ `prisma migrate dev` บน Production ให้ใช้ `npx prisma migrate deploy` แทน

### 4.5 รัน Backend Service

```bash
npm run dev
```

ตรวจสอบว่า backend เปิดใช้งาน:

```bash
curl http://localhost:3000/api/rooms
```

ถ้าได้ response แสดงว่า backend ทำงาน ✅

---

## ขั้นตอนที่ 5: ทดสอบ Backend API ด้วย Newman

จาก root repository:

```bash
cd ..
npx newman run newman/hotel-booking-collection.json \
  -e newman/hotel-booking-env.json \
  --env-var baseUrl=http://localhost:3000
```

ถ้าต้องการรายงาน HTML:

```bash
npx newman run newman/hotel-booking-collection.json \
  -e newman/hotel-booking-env.json \
  --env-var baseUrl=http://localhost:3000 \
  -r htmlextra
```

---

## ขั้นตอนที่ 6: รัน Frontend Local

**เปิด Terminal ใหม่** (อย่าปิด backend):

```bash
cd frontend
npm run dev
```

เปิดเบราว์เซอร์ที่:

```bash
http://localhost:5173
```

ตรวจสอบว่า:

- หน้า Login โหลดได้
- frontend สามารถเรียก backend API ได้ผ่าน `VITE_API_URL`
- สามารถ login ด้วย `admin/admin123`
- เข้าถึงหน้า Admin Dashboard ได้

---

## ขั้นตอนที่ 7: สร้าง Production Build และรัน Lint

```bash
npm run build
npm run lint
```

ถ้า build และ lint ผ่าน แสดงว่า frontend พร้อมสำหรับ deploy

---

## ขั้นตอนที่ 8: ตั้งค่า Vercel สำหรับ Frontend Deployment

### 8.1 สมัคร Vercel Account

1. ไปที่ https://vercel.com
2. Sign in with GitHub
3. ยืนยัน email

### 8.2 สร้าง Vercel Project

1. คลิก **Add New → Project**
2. เลือก repository `YOUR_USERNAME/booking-app-demo-2025`
3. ตั้งค่า:
   - **Framework Preset:** Vite
   - **Root Directory:** `frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
4. เพิ่ม Environment Variables:
   - `VITE_API_URL` = `https://your-backend.onrender.com`
5. คลิก **Deploy**

### 8.3 ดึง Vercel Token

1. Vercel Dashboard → Settings → Tokens
2. Create Token → ตั้งชื่อ "GitHub Actions"
3. Copy token → ใช้ใน GitHub Secrets

### 8.4 ดึง Vercel Org/Project IDs

```bash
npm i -g vercel
vercel login
cd frontend
vercel link
cat .vercel/project.json
```

จดค่า `orgId` และ `projectId`

---

## ขั้นตอนที่ 9: ตั้งค่า Render สำหรับ Backend Deployment

### 9.1 สมัคร Render Account

1. ไปที่ https://render.com
2. Sign in with GitHub

### 9.2 สร้าง PostgreSQL Database

1. คลิก **New → PostgreSQL**
2. ตั้งชื่อ `booking-db`
3. เลือก region ใกล้เคียง
4. คลิก **Create Database**
5. คัดลอก Internal Database URL ไปใส่ใน GitHub Secrets

### 9.3 สร้าง Web Service Backend

1. คลิก **New → Web Service**
2. เลือก repository `YOUR_USERNAME/booking-app-demo-2025`
3. ตั้งค่า:
   - **Name:** `booking-app-backend`
   - **Root Directory:** `backend`
   - **Environment:** Node
   - **Build Command:** `npm ci`
   - **Start Command:** `npm start`
4. เพิ่ม Environment Variables:
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
   - `DATABASE_URL` = (Render PostgreSQL URL)
   - `JWT_SECRET` = (สุ่ม 64 ตัวอักษร)
   - `CORS_ORIGIN` = (Vercel URL ของ frontend)
5. คลิก **Create Web Service**

### 9.4 ดึง Render Deploy Hook URL

1. Render Web Service → Settings → Deploy Hook
2. Copy URL เช่น `https://api.render.com/deploy/srv-xxx?key=yyy`

---

## ขั้นตอนที่ 10: ตั้งค่า GitHub Secrets

ไปที่ **Repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | ค่า | ที่มา |
|------------|-----|------|
| `VERCEL_TOKEN` | Vercel token | Vercel Dashboard |
| `VERCEL_ORG_ID` | orgId | .vercel/project.json |
| `VERCEL_PROJECT_ID` | projectId | .vercel/project.json |
| `RENDER_DEPLOY_HOOK_URL` | Render deploy hook URL | Render Settings |
| `VITE_API_URL` | `https://your-backend.onrender.com` | Render backend URL |
| `JWT_SECRET` | random 64-char string | สร้างเอง |

ตรวจสอบว่า secrets ทั้ง 6 รายการถูกสร้างเรียบร้อย

---

## ขั้นตอนที่ 11: Push และ Trigger Deployment

```bash
git add .
git commit -m "chore: combine setup, backend, frontend, and deployment lab"
git push origin main
```

เมื่อ push แล้ว:

- GitHub Actions จะรัน workflow
- Vercel จะ deploy frontend
- Render จะ deploy backend

---

## ขั้นตอนที่ 12: ตรวจสอบ CI Workflow

เปิดไฟล์ `.github/workflows/ci.yml` แล้วตรวจสอบว่า:

- มีขั้นตอนติดตั้ง dependencies
- มีขั้นตอนรัน Docker Compose / PostgreSQL
- มีคำสั่ง `npx prisma generate`
- มีคำสั่ง `npx prisma migrate dev --name init`
- มีคำสั่ง build frontend
- มีขั้นตอน deploy ไป Vercel และ Render

---

## ✅ Checklist

- [ ] Fork และ clone repository สำเร็จ
- [ ] สร้าง `backend/.env` และ `frontend/.env`
- [ ] ติดตั้ง dependencies ทั้ง root/backend/frontend
- [ ] backend รันได้ที่ `http://localhost:3000`
- [ ] frontend รันได้ที่ `http://localhost:5173`
- [ ] Newman API tests ผ่าน
- [ ] frontend build และ lint ผ่าน
- [ ] ตั้งค่า Vercel และ Render สำเร็จ
- [ ] ตั้งค่า GitHub Secrets ครบ
- [ ] Push แล้ว workflow รันสำเร็จ
- [ ] ตรวจสอบ deployment บน Vercel และ Render สำเร็จ

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)
