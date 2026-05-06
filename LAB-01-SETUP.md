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

# รัน PostgreSQL ด้วย Docker Compose
docker compose up -d

# สร้าง Prisma client
npx prisma generate

# รัน migration
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

## ขั้นตอนที่ 6: ตั้งค่า Vercel สำหรับ Frontend Deployment

### 6.1 สมัคร Vercel Account

1. ไปที่ [https://vercel.com](https://vercel.com)
2. **Sign in with GitHub**
3. ยืนยัน email

### 6.2 สร้าง Vercel Project

1. คลิก **Add New → Project**
2. เลือก repository `YOUR_USERNAME/booking-app-demo-2025`
3. ตั้งค่า:
   - **Framework Preset:** Vite
   - **Root Directory:** `frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
4. เพิ่ม Environment Variables:
   - `VITE_API_URL` = `https://your-backend.onrender.com` (จะกรอกทีหลัง)
5. คลิก **Deploy**

### 6.3 ดึง Vercel Tokens

ขั้นตอนดึง VERCEL_TOKEN:
1. Vercel Dashboard → Settings (icon บัญชี) → Tokens
2. Create Token → ตั้งชื่อ "GitHub Actions"
3. Copy token → เก็บไว้ใช้ใน GitHub Secrets

ขั้นตอนดึง VERCEL_ORG_ID และ VERCEL_PROJECT_ID:
1. ติดตั้ง Vercel CLI:
   ```bash
   npm i -g vercel
   ```
2. เข้าสู่ระบบ:
   ```bash
   vercel login
   ```
3. Link project (รันใน frontend/):
   ```bash
   cd frontend
   vercel link
   ```
4. ดู .vercel/project.json:
   ```bash
   cat .vercel/project.json
   ```
   จะเห็น `orgId` และ `projectId`

---

## ขั้นตอนที่ 7: ตั้งค่า Render สำหรับ Backend Deployment

### 7.1 สมัคร Render Account

1. ไปที่ [https://render.com](https://render.com)
2. **Sign in with GitHub**

### 7.2 สร้าง PostgreSQL Database

1. คลิก **New → PostgreSQL**
2. ตั้งชื่อ: `booking-db`
3. เลือก region ที่ใกล้ที่สุด
4. คลิก **Create Database**
5. Copy **Internal Database URL** → เก็บไว้ใช้ใน Environment Variables

### 7.3 สร้าง Web Service สำหรับ Backend

1. คลิก **New → Web Service**
2. เลือก repository `YOUR_USERNAME/booking-app-demo-2025`
3. ตั้งค่า:
   - **Name:** `booking-app-backend`
   - **Root Directory:** `backend`
   - **Environment:** `Node`
   - **Build Command:** `npm ci`
   - **Start Command:** `npm start`
4. เพิ่ม Environment Variables:
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
   - `DATABASE_URL` = (จาก Render PostgreSQL)
   - `JWT_SECRET` = (สุ่มสตริง 64 ตัวอักษร)
   - `CORS_ORIGIN` = (Vercel URL ของ frontend)
5. คลิก **Create Web Service**

### 7.4 ดึง Deploy Hook URL

1. Render Web Service → Settings → Deploy Hook
2. Copy URL (จะมีลักษณะ: `https://api.render.com/deploy/srv-xxx?key=yyy`)

---

## ขั้นตอนที่ 8: ตั้งค่า GitHub Secrets

ไปที่ **Repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | ค่า | ที่มา |
|------------|-----|------|
| `VERCEL_TOKEN` | `xxxxxxxx` | Vercel → Settings → Tokens |
| `VERCEL_ORG_ID` | `team_xxxxx` | `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | `prj_xxxxx` | `.vercel/project.json` |
| `RENDER_DEPLOY_HOOK_URL` | `https://api.render.com/...` | Render → Settings → Deploy Hook |
| `VITE_API_URL` | `https://xxx.onrender.com` | Render service URL |
| `JWT_SECRET` | `random-64-char-string` | สุ่มขึ้นมาเอง |

### ตรวจสอบ Secrets

```
GitHub → Repository → Settings → Secrets and variables → Actions
```

ควรเห็น secrets ทั้ง 6 รายการ:

```
✅ VERCEL_TOKEN
✅ VERCEL_ORG_ID
✅ VERCEL_PROJECT_ID
✅ RENDER_DEPLOY_HOOK_URL
✅ VITE_API_URL
✅ JWT_SECRET
```

---

## ขั้นตอนที่ 9: ทดสอบ Local ด้วย Docker Compose

แทนการรัน `npm run dev` ให้ใช้ Docker Compose เพื่อจำลอง production environment:

```bash
# หยุด npm run dev ก่อน (ถ้ากำลังรัน)
# Ctrl+C เพื่อหยุด

# รันทั้งระบบด้วย Docker Compose
docker compose up --build
```

ระบบจะรันที่:
- Frontend: `http://localhost:5173`
- Backend: `http://localhost:3000`
- Database: `localhost:5432`

---

## ขั้นตอนที่ 10: Push และ Trigger Deployment

```bash
# Commit การเปลี่ยนแปลง
git add .
git commit -m "feat: setup environment and deployment configuration"

# Push ขึ้น GitHub
git push origin main
```

ตรวจสอบ GitHub Actions:
- ไปที่ Repository → Actions
- จะเห็น workflow `CI` รันอัตโนมัติ
- เมื่อสำเร็จ จะ deploy ไป Vercel และ Render อัตโนมัติ

---

## ขั้นตอนที่ 11: ตรวจสอบ workflow

เปิดไฟล์:

```bash
cat .github/workflows/ci.yml
```

เข้าใจขั้นตอนใน workflow:
- ติดตั้ง backend dependencies
- รัน Docker Compose สำหรับ PostgreSQL
- สร้าง Prisma client
- รัน Prisma migration
- ติดตั้ง frontend dependencies
- Build frontend
- Deploy ไป Vercel และ Render

---

## ✅ Checklist ก่อนไปต่อ

- [ ] Fork และ clone repository สำเร็จ
- [ ] สร้าง `backend/.env` และ `frontend/.env`
- [ ] ติดตั้ง dependencies ทั้ง root/backend/frontend
- [ ] backend รันได้ที่ `http://localhost:3000`
- [ ] frontend รันได้ที่ `http://localhost:5173`
- [ ] สมัคร Vercel account และสร้าง project
- [ ] สมัคร Render account และสร้าง database + web service
- [ ] ตั้งค่า GitHub Secrets ครบทั้ง 6 รายการ
- [ ] ทดสอบด้วย `docker compose up --build`
- [ ] Push ขึ้น GitHub และ workflow รันสำเร็จ
- [ ] Deploy ไป Vercel และ Render สำเร็จ

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-02 Backend →](LAB-02-BACKEND.md)
