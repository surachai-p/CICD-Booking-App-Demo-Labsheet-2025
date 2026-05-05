# 📖 ทฤษฎีก่อนการทดลอง: CI/CD & GitHub Actions

[← กลับ README](README.md) | [ถัดไป: LAB-01 Setup →](LAB-01-SETUP.md)

---

## 1. CI/CD คืออะไร?

### 1.1 ความหมายและความสำคัญ

**CI/CD** ย่อมาจาก **Continuous Integration / Continuous Deployment (หรือ Delivery)**

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                            │
│                                                              │
│  Code → Build → Test → Release → Deploy → Monitor           │
│   │       │       │       │         │         │             │
│   │       │       │       │         └── Feedback  │
│   │       │       │       │                         │
│   └── git push → trigger workflow                         │
└─────────────────────────────────────────────────────────────┘
```

| คำศัพท์ | ความหมาย |
|--------|---------|
| **CI** (Continuous Integration) | การรวมโค้ดจากหลายคนเข้าด้วยกันบ่อยๆ พร้อม test อัตโนมัติ |
| **CD** (Continuous Delivery) | โค้ดถูกเตรียมไว้สำหรับ deploy ได้ตลอดเวลา |
| **CD** (Continuous Deployment) | deploy ไป production อัตโนมัติเมื่อ test ผ่าน |

### 1.2 ประโยชน์ของ CI/CD

```
ไม่มี CI/CD                     มี CI/CD
─────────────────────            ──────────────────────────
❌ Deploy ด้วยมือ                 ✅ Deploy อัตโนมัติ
❌ ลืม run test ก่อน push        ✅ Test ทุกครั้งที่ push
❌ "ทำงานในเครื่องฉัน" ปัญหา    ✅ Environment เดียวกันทุกที่
❌ Bug เจอเมื่อ production แล้ว  ✅ Bug เจอตั้งแต่ต้น
❌ Deploy ช้า กลัวผิดพลาด        ✅ Deploy เร็ว มั่นใจ
```

---

## 2. GitHub Actions คืออะไร?

### 2.1 ภาพรวม

**GitHub Actions** คือ CI/CD Platform บน GitHub ใช้ไฟล์ YAML เพื่อกำหนดกระบวนการอัตโนมัติ

```
GitHub Repository
└── .github/
    └── workflows/
        └── ci.yml
```

ใน repository เป้าหมาย จะมี workflow อยู่ที่ `.github/workflows/ci.yml` ซึ่งรันบน **self-hosted runner** และทำงานกับทั้ง backend และ frontend.

### 2.2 ส่วนประกอบของ Workflow

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install backend dependencies
        run: |
          cd backend
          npm install
      - name: Start PostgreSQL with Docker Compose
        run: |
          cd backend
          docker compose up -d
      - name: Generate Prisma client
        run: |
          cd backend
          npx prisma generate
      - name: Run backend migrations
        run: |
          cd backend
          npx prisma migrate dev --name init
      - name: Install frontend dependencies
        run: |
          cd frontend
          npm install
      - name: Build frontend
        run: |
          cd frontend
          npm run build
```

### 2.3 คำอธิบาย Keywords สำคัญ

#### 🔑 `on:` — Triggers (เงื่อนไขการเริ่มทำงาน)

```yaml
on:
  push:
    branches:
      - main
  pull_request:
```

#### 🔑 `runs-on:` — Runner ที่ใช้

- `ubuntu-latest` = GitHub-hosted runner
- `self-hosted` = เครื่องของเราเอง หรือ VM ที่ติดตั้ง GitHub Actions Runner

#### 🔑 `steps:` — ขั้นตอนภายใน job

```yaml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4

  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: '20'

  - name: Install dependencies
    run: npm install
```

---

## 3. Secrets & Environment Variables

### 3.1 ความแตกต่าง

```
┌─────────────────────┬─────────────────────────────────────────┐
│      Secrets        │         Environment Variables           │
├─────────────────────┼─────────────────────────────────────────┤
│ ✅ เข้ารหัส         │ ❌ เปิดเผยได้ใน workflow              │
│ ✅ ไม่สามารถดูค่าได้ │ ✅ สามารถอ่านได้ใน logs (ถ้า echo)    │
│ ใช้กับ API keys     │ ใช้กับค่า config เช่น NODE_ENV, URL    │
└─────────────────────┴─────────────────────────────────────────────┘
```

### 3.2 วิธีตั้งค่า GitHub Secrets

```
GitHub Repository
  → Settings
    → Secrets and variables
      → Actions
        → New repository secret
```

---

## 4. Self-hosted Runner

### 4.1 ทำไมต้องใช้ self-hosted runner?

- รัน Docker Compose ได้บนเครื่องของเรา
- ใช้ resource ของเครื่องเอง
- เหมาะกับโปรเจคที่ต้องติดตั้งซอฟต์แวร์เฉพาะ

### 4.2 ข้อควรระวัง

- อัปเดตระบบปฏิบัติการ และ GitHub Actions Runner
- ตรวจสอบการเข้าถึงเครือข่าย
- อย่าใช้ runner ที่เปิด port สำคัญโดยไม่ตั้งค่าไฟร์วอลล์

---

## 5. CI/CD ใน repository นี้

โครงการ `booking-app-demo-2025` มีทั้ง:

- `backend/` → Node.js + Express + Prisma + PostgreSQL
- `frontend/` → React + Vite + Tailwind
- `newman/` → API testing collection
- `tests/robot/` → UI automation test suite
- `.github/workflows/ci.yml` → CI workflow

เมื่อ `git push` ไป `main` หรือเปิด PR ระบบจะรัน workflow เพื่อ build backend และ frontend ชุดเดียวกัน.
