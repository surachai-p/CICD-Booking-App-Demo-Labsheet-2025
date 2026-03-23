# ⚙️ LAB-01: เตรียม Repository & Environment

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-02 Backend →](LAB-02-BACKEND.md)

---

## 🎯 เป้าหมาย

- Fork repository และ clone มาที่เครื่อง
- ตั้งค่า Vercel และ Render accounts
- สร้าง GitHub Secrets ที่จำเป็น
- เข้าใจโครงสร้างของ project

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

# ตรวจสอบโครงสร้าง
ls -la
```

### 1.3 ดู Branch ที่มีอยู่

```bash
git branch -a
git log --oneline -5
```

---

## ขั้นตอนที่ 2: สร้าง Environment Files

### 2.1 Frontend `.env`

สร้างไฟล์ `frontend/.env` (และ `.env.example` สำหรับ template):

```bash
# สร้างจาก example
cp frontend/.env.example frontend/.env
```

เนื้อหา `frontend/.env.example`:

```bash
# ─── API Configuration ─────────────────────────────────────────
# URL ของ Backend API (เปลี่ยนเป็น Render URL เมื่อ deploy)
VITE_API_URL=http://localhost:3000

# ─── App Configuration ─────────────────────────────────────────
VITE_APP_NAME=Booking App Demo
VITE_APP_VERSION=1.0.0

# ─── Feature Flags ─────────────────────────────────────────────
VITE_ENABLE_MOCK_API=false
```

> ⚠️ **สำคัญ:** Frontend ใช้ Vite → ตัวแปร **ต้องขึ้นต้นด้วย `VITE_`** เท่านั้น  
> ตัวแปรที่ไม่ขึ้นต้นด้วย `VITE_` จะไม่ถูก inject เข้าไปใน browser

### 2.2 Backend `.env`

สร้างไฟล์ `backend/.env.example`:

```bash
# ─── Application ───────────────────────────────────────────────
NODE_ENV=development
PORT=3000

# ─── Database ──────────────────────────────────────────────────
# PostgreSQL connection string
# Format: postgresql://USER:PASSWORD@HOST:PORT/DATABASE
DATABASE_URL=postgresql://postgres:password@localhost:5432/booking_db

# ─── JWT Authentication ────────────────────────────────────────
JWT_SECRET=change-this-to-random-64-char-string-in-production
JWT_EXPIRES_IN=7d

# ─── CORS Configuration ────────────────────────────────────────
# Production: เปลี่ยนเป็น Vercel URL จริง
CORS_ORIGIN=http://localhost:5173

# ─── Rate Limiting ─────────────────────────────────────────────
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# ─── API Keys (ตัวอย่าง) ───────────────────────────────────────
# EMAIL_SERVICE_API_KEY=your-sendgrid-key
# PAYMENT_API_KEY=your-stripe-key
```

```bash
cp backend/.env.example backend/.env
# แก้ไขค่าต่างๆ ตามสภาพแวดล้อมของคุณ
```

---

## ขั้นตอนที่ 3: ตั้งค่า Vercel

### 3.1 สมัคร / เข้าสู่ระบบ Vercel

1. ไปที่ [https://vercel.com](https://vercel.com)
2. **Sign in with GitHub**

### 3.2 สร้าง Project บน Vercel

1. คลิก **Add New → Project**
2. เลือก repository `booking-app-demo-2025`
3. ตั้งค่า:
   - **Framework Preset:** Vite
   - **Root Directory:** `frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
4. เพิ่ม Environment Variables:
   - `VITE_API_URL` = `https://your-backend.onrender.com` (จะกรอกทีหลัง)
5. คลิก **Deploy**

### 3.3 ดึง Vercel Tokens สำหรับ GitHub Actions

```
ขั้นตอนดึง VERCEL_TOKEN:
1. Vercel Dashboard → Settings (icon บัญชี) → Tokens
2. Create Token → ตั้งชื่อ "GitHub Actions"
3. Copy token → เก็บไว้ใช้ใน GitHub Secrets

ขั้นตอนดึง VERCEL_ORG_ID และ VERCEL_PROJECT_ID:
1. ติดตั้ง Vercel CLI:
   npm i -g vercel

2. เข้าสู่ระบบ:
   vercel login

3. Link project (รันใน frontend/):
   cd frontend
   vercel link

4. ดู .vercel/project.json:
   cat .vercel/project.json
   # จะเห็น orgId และ projectId
```

---

## ขั้นตอนที่ 4: ตั้งค่า Render

### 4.1 สมัคร / เข้าสู่ระบบ Render

1. ไปที่ [https://render.com](https://render.com)
2. **Sign in with GitHub**

### 4.2 สร้าง Web Service บน Render

1. คลิก **New → Web Service**
2. เลือก repository `booking-app-demo-2025`
3. ตั้งค่า:
   - **Name:** `booking-app-backend`
   - **Root Directory:** `backend`
   - **Environment:** `Node`
   - **Build Command:** `npm ci`
   - **Start Command:** `npm start`
4. เพิ่ม Environment Variables (ใน Render Dashboard):
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
   - `DATABASE_URL` = (จาก Render PostgreSQL)
   - `JWT_SECRET` = (สุ่มสตริง 64 ตัวอักษร)
   - `CORS_ORIGIN` = (Vercel URL ของ frontend)
5. คลิก **Create Web Service**

### 4.3 สร้าง PostgreSQL Database บน Render

1. คลิก **New → PostgreSQL**
2. ตั้งชื่อ: `booking-db`
3. คลิก **Create Database**
4. Copy **Internal Database URL** → ใส่ใน Backend Environment Variable `DATABASE_URL`

### 4.4 ดึง Deploy Hook URL

```
Render Web Service → Settings → Deploy Hook
→ Copy URL (จะมีลักษณะ: https://api.render.com/deploy/srv-xxx?key=yyy)
```

---

## ขั้นตอนที่ 5: ตั้งค่า GitHub Secrets

ไปที่ **Repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | ค่า | ที่มา |
|------------|-----|------|
| `VERCEL_TOKEN` | `xxxxxxxx` | Vercel → Settings → Tokens |
| `VERCEL_ORG_ID` | `team_xxxxx` | `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | `prj_xxxxx` | `.vercel/project.json` |
| `RENDER_DEPLOY_HOOK_URL` | `https://api.render.com/...` | Render → Settings → Deploy Hook |
| `VITE_API_URL` | `https://xxx.onrender.com` | Render service URL |

### ตรวจสอบ Secrets

```
GitHub → Repository → Settings → Secrets and variables → Actions
```

ควรเห็น secrets ทั้ง 5 รายการ:

```
✅ VERCEL_TOKEN
✅ VERCEL_ORG_ID
✅ VERCEL_PROJECT_ID
✅ RENDER_DEPLOY_HOOK_URL
✅ VITE_API_URL
```

---

## ขั้นตอนที่ 6: สร้าง Workflow Directory

```bash
# สร้าง directory สำหรับ GitHub Actions workflows
mkdir -p .github/workflows

# ตรวจสอบโครงสร้าง
tree .github/
# .github/
# └── workflows/
```

---

## ✅ Checklist ก่อนไปขั้นตอนถัดไป

- [ ] Fork และ clone repository สำเร็จ
- [ ] สร้าง `frontend/.env` และ `backend/.env` แล้ว
- [ ] Vercel project สร้างแล้ว (มี URL เช่น `https://booking-app-xxx.vercel.app`)
- [ ] Render web service สร้างแล้ว (มี URL เช่น `https://booking-app-backend.onrender.com`)
- [ ] Render PostgreSQL database สร้างแล้ว
- [ ] GitHub Secrets ครบทั้ง 5 รายการ
- [ ] Directory `.github/workflows/` สร้างแล้ว

---

[← ทฤษฎี](LAB-THEORY.md) | [ถัดไป: LAB-02 Backend →](LAB-02-BACKEND.md)
