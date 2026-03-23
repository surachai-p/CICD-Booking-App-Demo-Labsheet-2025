# 📖 ทฤษฎีก่อนการทดลอง: CI/CD & GitHub Actions

[← กลับ README](../README.md) | [ถัดไป: LAB-01 Setup →](LAB-01-SETUP.md)

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
│   │       │       │       │         │         └── Feedback  │
│   │       │       │       │         └── Vercel / Render     │
│   │       │       │       └── GitHub Release                │
│   │       │       └── Automated Tests (Unit, Integration)   │
│   │       └── npm build / tsc compile                       │
│   └── git push → trigger workflow                           │
└─────────────────────────────────────────────────────────────┘
```

| คำศัพท์ | ความหมาย |
|--------|---------|
| **CI** (Continuous Integration) | การรวมโค้ดจากหลายคนเข้าด้วยกันบ่อยๆ พร้อม test อัตโนมัติ |
| **CD** (Continuous Delivery) | โค้ดพร้อม deploy ไป production ได้ตลอดเวลา |
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

**GitHub Actions** คือ CI/CD Platform ที่ built-in อยู่ใน GitHub ใช้ไฟล์ YAML เพื่อกำหนดกระบวนการอัตโนมัติ

```
GitHub Repository
└── .github/
    └── workflows/
        ├── frontend-ci-cd.yml   ← ไฟล์ workflow สำหรับ Frontend
        └── backend-ci-cd.yml    ← ไฟล์ workflow สำหรับ Backend
```

### 2.2 ส่วนประกอบของ Workflow

```yaml
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. WORKFLOW METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
name: My CI/CD Pipeline          # ชื่อ workflow (แสดงใน GitHub UI)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. TRIGGERS - เมื่อไหร่จะทำงาน
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
on:
  push:
    branches: [main, develop]    # ทำงานเมื่อ push ไป main หรือ develop
    paths:
      - 'frontend/**'            # และมีการเปลี่ยนแปลงไฟล์ใน frontend/
  pull_request:
    branches: [main]             # ทำงานเมื่อมี PR ไป main

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. ENVIRONMENT VARIABLES (Global)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
env:
  NODE_VERSION: '18'             # ตัวแปรใช้ได้ทุก job

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. JOBS - กลุ่มงาน (รันแบบ parallel โดย default)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jobs:
  test:                          # ชื่อ job
    runs-on: ubuntu-latest       # OS ที่รัน (runner)
    
    steps:                       # รายการคำสั่ง (รันตามลำดับ)
      - name: Checkout code
        uses: actions/checkout@v4  # ใช้ action สำเร็จรูป
      
      - name: Install Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}  # อ้างอิง env var
      
      - name: Install dependencies
        run: npm ci               # รัน shell command
      
      - name: Run tests
        run: npm test
```

### 2.3 คำอธิบาย Keywords สำคัญ

#### 🔑 `on:` — Triggers (เงื่อนไขการเริ่มทำงาน)

```yaml
on:
  # ─── Event: push ───────────────────────────────────────────
  push:
    branches:
      - main          # ทำงานเมื่อ push ไป main
      - 'release/**'  # หรือ branch ที่ขึ้นต้นด้วย release/
    paths:
      - 'src/**'      # กรอง: เฉพาะไฟล์ใน src/ เปลี่ยน
      - '**.ts'       # หรือไฟล์ .ts ใดก็ได้
    tags:
      - 'v*'          # เมื่อสร้าง tag เช่น v1.0.0

  # ─── Event: pull_request ───────────────────────────────────
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]  # ประเภท PR event

  # ─── Event: schedule (Cron) ────────────────────────────────
  schedule:
    - cron: '0 2 * * *'    # ทุกวัน เวลา 02:00 UTC
    # ┌──── minute (0-59)
    # │ ┌── hour   (0-23)
    # │ │ ┌ day    (1-31)
    # │ │ │ ┌ month (1-12)
    # │ │ │ │ ┌ weekday (0-7, 0=Sun)
    # │ │ │ │ │
    # 0 2 * * *

  # ─── Event: manual trigger ─────────────────────────────────
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deploy environment'
        type: choice
        options: [staging, production]
        required: true
```

#### 🔑 `jobs:` — งานที่ต้องทำ

```yaml
jobs:
  # Job 1: รันอิสระ
  test:
    runs-on: ubuntu-latest       # GitHub-hosted runner
    timeout-minutes: 10          # ถ้าเกิน 10 นาที ยกเลิก

  # Job 2: รอให้ job test เสร็จก่อน
  deploy:
    needs: test                  # ต้องรอ test ผ่านก่อน
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'  # รันเฉพาะเมื่อเป็น main branch

  # Job 3: รอหลาย jobs
  notify:
    needs: [test, deploy]        # รอทั้ง test และ deploy
```

#### 🔑 `steps:` — ขั้นตอนภายใน job

```yaml
steps:
  # ─── ใช้ Action สำเร็จรูป ─────────────────────────────────
  - name: Checkout repository
    uses: actions/checkout@v4        # action@version

  # ─── รัน Shell Command ────────────────────────────────────
  - name: Run multiple commands
    run: |                           # | หมายถึง multi-line
      echo "Step 1"
      npm install
      npm test

  # ─── ส่งค่าระหว่าง steps ──────────────────────────────────
  - name: Get version
    id: version                      # ตั้ง id เพื่อ reference
    run: echo "ver=1.0.0" >> $GITHUB_OUTPUT

  - name: Use version
    run: echo "Version is ${{ steps.version.outputs.ver }}"

  # ─── ใช้ secrets ──────────────────────────────────────────
  - name: Deploy
    run: ./deploy.sh
    env:
      API_TOKEN: ${{ secrets.API_TOKEN }}  # อ่านจาก GitHub Secrets
```

#### 🔑 `uses:` — Actions ที่ใช้บ่อย

| Action | ใช้ทำอะไร |
|--------|---------|
| `actions/checkout@v4` | Clone repository มายัง runner |
| `actions/setup-node@v4` | ติดตั้ง Node.js |
| `actions/cache@v4` | Cache dependencies ให้เร็วขึ้น |
| `actions/upload-artifact@v4` | อัปโหลด build output |
| `actions/download-artifact@v4` | ดาวน์โหลด artifact |

---

## 3. Secrets & Environment Variables

### 3.1 ความแตกต่าง

```
┌─────────────────────┬─────────────────────────────────────────┐
│      Secrets        │         Environment Variables           │
├─────────────────────┼─────────────────────────────────────────┤
│ ✅ เข้ารหัส (AES)   │ ❌ เห็นได้ใน workflow file              │
│ ❌ ดูค่าไม่ได้      │ ✅ ดูค่าได้ (ใน logs)                   │
│ สำหรับ: passwords   │ สำหรับ: URL, version, config           │
│         API keys    │         NODE_ENV, REGION               │
│         tokens      │                                         │
│                     │                                         │
│ ${{ secrets.NAME }} │ ${{ env.NAME }} หรือ $NAME              │
└─────────────────────┴─────────────────────────────────────────┘
```

### 3.2 วิธีตั้งค่า GitHub Secrets

```
GitHub Repository
  → Settings
    → Secrets and variables
      → Actions
        → New repository secret
          → Name: RENDER_API_KEY
          → Value: [your-api-key]
```

### 3.3 ตัวอย่างการใช้

```yaml
env:
  NODE_VERSION: '18'           # ✅ สาธารณะ — ใส่ใน workflow ได้
  API_URL: 'https://api.example.com'  # ✅ สาธารณะ

steps:
  - name: Deploy to Render
    env:
      RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}     # 🔒 ลับ
      DATABASE_URL: ${{ secrets.DATABASE_URL }}          # 🔒 ลับ
    run: ./deploy.sh
```

---

## 4. Workflow Contexts

### 4.1 Context Variables ที่ใช้บ่อย

```yaml
# ─── github context ───────────────────────────────────────────
${{ github.sha }}          # Commit SHA เช่น a1b2c3d...
${{ github.ref }}          # Full ref เช่น refs/heads/main
${{ github.ref_name }}     # Branch/tag name เช่น main
${{ github.actor }}        # User ที่ trigger เช่น john-doe
${{ github.repository }}   # owner/repo เช่น john/booking-app
${{ github.event_name }}   # push, pull_request, schedule
${{ github.run_number }}   # เลข run เช่น 42
${{ github.run_id }}       # ID ของ run นี้

# ─── env context ──────────────────────────────────────────────
${{ env.NODE_VERSION }}    # อ้างอิง env var ที่ตั้งไว้

# ─── secrets context ──────────────────────────────────────────
${{ secrets.API_KEY }}     # อ้างอิง secret

# ─── steps context ────────────────────────────────────────────
${{ steps.STEP_ID.outputs.VALUE }}   # output จาก step อื่น

# ─── needs context ────────────────────────────────────────────
${{ needs.JOB_NAME.outputs.VALUE }}  # output จาก job อื่น
```

---

## 5. Deployment Targets

### 5.1 Vercel (Frontend)

```
Vercel คือ Platform as a Service (PaaS) สำหรับ frontend
─────────────────────────────────────────────────────────
✅ รองรับ React, Next.js, Vue, Svelte
✅ Auto HTTPS
✅ Edge Network (CDN ทั่วโลก)
✅ Preview deployments สำหรับทุก PR
✅ Free tier เพียงพอสำหรับ demo
```

**วิธี Deploy ผ่าน GitHub Actions:**
```yaml
- name: Deploy to Vercel
  uses: amondnet/vercel-action@v25
  with:
    vercel-token: ${{ secrets.VERCEL_TOKEN }}
    vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
    vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
    working-directory: ./frontend
```

### 5.2 Render (Backend)

```
Render คือ Cloud Platform สำหรับ backend services
─────────────────────────────────────────────────
✅ รองรับ Node.js, Python, Ruby, Go, Rust
✅ PostgreSQL managed database
✅ Auto HTTPS
✅ Auto-deploy จาก GitHub
✅ Free tier (sleep หลัง 15 นาที)
```

**วิธี Deploy ผ่าน GitHub Actions (Webhook):**
```yaml
- name: Deploy to Render
  run: |
    curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK_URL }}"
```

---

## 6. NGINX & Security

### 6.1 Cross-Site Scripting (XSS) คืออะไร?

**XSS** คือการโจมตีที่ผู้ไม่หวังดีแทรก JavaScript อันตรายเข้าไปในหน้าเว็บ

```
ตัวอย่างการโจมตี XSS:
──────────────────────────────────────────────────
ผู้โจมตีส่งข้อความ: <script>alert('XSS!')</script>
ถ้าเว็บไม่ป้องกัน → script นั้นรันในเบราว์เซอร์ผู้ใช้
```

### 6.2 Security Headers ป้องกัน XSS

```nginx
# ─── ป้องกัน XSS ──────────────────────────────────────────────
add_header X-XSS-Protection "1; mode=block" always;

# ─── ป้องกัน Content Sniffing ────────────────────────────────
add_header X-Content-Type-Options "nosniff" always;

# ─── ควบคุม iframe ────────────────────────────────────────────
add_header X-Frame-Options "SAMEORIGIN" always;

# ─── Content Security Policy ──────────────────────────────────
add_header Content-Security-Policy "
  default-src 'self';
  script-src 'self' 'unsafe-inline';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
" always;

# ─── CORS Headers ─────────────────────────────────────────────
add_header Access-Control-Allow-Origin "https://booking-app.vercel.app" always;
add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
```

### 6.3 .env File Structure

```bash
# ─── Application ──────────────────────────────────────────────
NODE_ENV=production
PORT=3000

# ─── Database ─────────────────────────────────────────────────
DATABASE_URL=postgresql://user:password@host:5432/dbname

# ─── JWT Authentication ───────────────────────────────────────
JWT_SECRET=your-super-secret-key-min-32-chars
JWT_EXPIRES_IN=7d

# ─── CORS ─────────────────────────────────────────────────────
CORS_ORIGIN=https://your-frontend.vercel.app

# ─── API Keys ─────────────────────────────────────────────────
PAYMENT_API_KEY=pk_live_xxxxx
EMAIL_API_KEY=SG.xxxxx
```

---

## 7. Testing Pyramid

```
                    ┌─────────────────┐
                    │   E2E Tests     │  น้อยที่สุด, ช้า, ครอบคลุม
                    │  (Playwright)   │  ทดสอบ user flow จริง
                    └────────┬────────┘
               ┌─────────────┴─────────────┐
               │    Integration Tests       │  ทดสอบหลาย component
               │  (Supertest / RTL)         │  ร่วมกัน
               └─────────────┬─────────────┘
          ┌───────────────────┴───────────────────┐
          │           Unit Tests                   │  มากที่สุด, เร็ว
          │  (Jest / Vitest)                       │  ทดสอบแยกชิ้น
          └───────────────────────────────────────┘
```

| ประเภท | เครื่องมือ | ทดสอบอะไร |
|--------|----------|----------|
| **Unit** | Jest, Vitest | Function, Component เดี่ยว |
| **Integration** | Supertest, RTL | API endpoints, Component interaction |
| **E2E** | Playwright, Cypress | User flow ทั้งระบบ |
| **Security** | npm audit, OWASP ZAP | ช่องโหว่ความปลอดภัย |

---

## 8. สรุป Flow การทำงาน CI/CD ของ Lab นี้

```
┌─── Developer ─────────────────────────────────────────────────┐
│                                                                 │
│  1. แก้ไขโค้ด (frontend หรือ backend)                         │
│  2. git add . && git commit -m "feat: add booking form"        │
│  3. git push origin main                                        │
│                                                                 │
└──────────────────────────┬──────────────────────────────────── ┘
                           │
                           ▼ (trigger อัตโนมัติ)
┌─── GitHub Actions ────────────────────────────────────────────┐
│                                                                 │
│  ┌── Frontend Workflow ──────────────────────────────────┐    │
│  │  ① Checkout code                                       │    │
│  │  ② Setup Node.js 18                                    │    │
│  │  ③ npm ci (install with cache)                         │    │
│  │  ④ npm run lint (ESLint check)                         │    │
│  │  ⑤ npm test (Vitest unit tests)                        │    │
│  │  ⑥ npm run test:integration                            │    │
│  │  ⑦ npm run build (Vite build)                          │    │
│  │  ⑧ Deploy → Vercel ✅                                  │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌── Backend Workflow ───────────────────────────────────┐    │
│  │  ① Checkout code                                       │    │
│  │  ② Setup Node.js 18                                    │    │
│  │  ③ npm ci (install with cache)                         │    │
│  │  ④ npm run lint (ESLint check)                         │    │
│  │  ⑤ npm test (Jest unit tests)                          │    │
│  │  ⑥ npm run test:integration (Supertest)                │    │
│  │  ⑦ npm run test:security                               │    │
│  │  ⑧ npm audit (vulnerability scan)                      │    │
│  │  ⑨ Deploy → Render ✅                                  │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────── ┘
```

---

## ❓ คำถามทบทวนทฤษฎี

ตอบคำถามต่อไปนี้ก่อนเริ่มทดลอง:

1. CI/CD ต่างจากการ deploy ด้วยมือยังไง?
2. `on: push` กับ `on: pull_request` ต่างกันอย่างไร?
3. ทำไมถึงต้องใช้ `secrets` แทนการเขียน API key ตรงๆ ใน workflow file?
4. `needs:` ใน jobs ใช้ทำอะไร?
5. XSS คืออะไร และ NGINX ป้องกันยังไง?

---

[← กลับ README](../README.md) | [ถัดไป: LAB-01 Setup →](LAB-01-SETUP.md)
