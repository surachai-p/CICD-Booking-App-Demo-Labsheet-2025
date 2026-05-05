# 🚀 Lab: CI/CD Pipeline with GitHub Actions
## Booking App Demo 2025 — Vercel + Render Deployment

> **Repository:** `https://github.com/surachai-p/booking-app-demo-2025`  
> **ระดับ:** ปริญญาตรี  
> **เวลา:** 4–5 ชั่วโมง  

---

## 🗂️ สารบัญใบงาน

| ไฟล์ | หัวข้อ | เวลา |
|------|--------|------|
| [📖 LAB-THEORY.md](docs/LAB-THEORY.md) | ทฤษฎี GitHub Actions & CI/CD | อ่านก่อนทดลอง |
| [⚙️ LAB-01-SETUP.md](docs/LAB-01-SETUP.md) | เตรียม Repository & Environment | 30 นาที |
| [🔧 LAB-02-BACKEND.md](docs/LAB-02-BACKEND.md) | Backend Testing & Deploy to Render | 60 นาที |
| [🎨 LAB-03-FRONTEND.md](docs/LAB-03-FRONTEND.md) | Frontend Testing & Deploy to Vercel | 60 นาที |
| [🔒 LAB-04-SECURITY.md](docs/LAB-04-SECURITY.md) | Security Testing & NGINX Config | 45 นาที |
| [📝 LAB-ASSIGNMENT.md](docs/LAB-ASSIGNMENT.md) | ใบงานส่ง & คำถาม | ส่งท้ายคาบ |

---

## 🎯 วัตถุประสงค์การทดลอง

หลังจากทดลองเสร็จ นักศึกษาจะสามารถ:

1. **อธิบาย** กระบวนการ CI/CD และ GitHub Actions workflow ได้
2. **เขียน** GitHub Actions workflow สำหรับ automated testing ทั้ง frontend และ backend
3. **ตั้งค่า** Environment Variables และ Secrets ใน GitHub อย่างปลอดภัย
4. **Deploy** Frontend ไปยัง Vercel และ Backend ไปยัง Render แบบอัตโนมัติ
5. **ทดสอบ** ระบบด้านความปลอดภัย (XSS, CORS, Security Headers)
6. **ตั้งค่า** NGINX เพื่อป้องกัน Cross-Site Scripting (XSS)

---

## 📐 สถาปัตยกรรมระบบ

```
┌─────────────────────────────────────────────────────────────────┐
│                    Developer Workstation                         │
│  ┌─────────────┐   git push   ┌──────────────────────────────┐  │
│  │  Source Code │ ──────────▶  │      GitHub Repository       │  │
│  └─────────────┘              │  booking-app-demo-2025        │  │
└──────────────────────────────│──────────────────────────────│──┘
                                └──────────────────────────────┘
                                           │
                          ┌────────────────┴────────────────┐
                          │        GitHub Actions            │
                          │  ┌──────────┐  ┌─────────────┐  │
                          │  │ Frontend │  │   Backend   │  │
                          │  │Workflow  │  │  Workflow   │  │
                          │  └────┬─────┘  └──────┬──────┘  │
                          └───────│────────────────│─────────┘
                                  │                │
                    ┌─────────────▼───┐  ┌─────────▼──────────┐
                    │    Vercel       │  │      Render         │
                    │  (Frontend)     │  │    (Backend)        │
                    │  React + Vite   │  │  Node.js/Express    │
                    │                 │  │  + PostgreSQL       │
                    └─────────────────┘  └────────────────────┘
                             │                      │
                             └──────────┬───────────┘
                                        │
                               ┌────────▼────────┐
                               │   End Users      │
                               │  (Browser)       │
                               └─────────────────┘
```

---

## 🛠️ เครื่องมือที่ต้องใช้

| เครื่องมือ | เวอร์ชัน | ดาวน์โหลด |
|-----------|---------|-----------|
| Git | ≥ 2.40 | https://git-scm.com |
| Node.js | ≥ 18 LTS | https://nodejs.org |
| VS Code | ล่าสุด | https://code.visualstudio.com |
| GitHub Account | - | https://github.com |
| Vercel Account | - | https://vercel.com |
| Render Account | - | https://render.com |

---

## 🗓️ กระบวนการ CI/CD ที่จะสร้าง

```
git push
    │
    ├──▶ [ Frontend Workflow ]
    │         │
    │         ├─ ✅ Install Dependencies
    │         ├─ ✅ Lint & Format Check
    │         ├─ ✅ Unit Tests (Vitest)
    │         ├─ ✅ Integration Tests
    │         ├─ ✅ Security Scan (OWASP)
    │         ├─ ✅ Build Production
    │         └─ ✅ Deploy → Vercel
    │
    └──▶ [ Backend Workflow ]
              │
              ├─ ✅ Install Dependencies
              ├─ ✅ Lint Check (ESLint)
              ├─ ✅ Unit Tests (Jest)
              ├─ ✅ Integration Tests (Supertest)
              ├─ ✅ Security Scan (npm audit)
              ├─ ✅ Security Headers Test
              └─ ✅ Deploy → Render
```

---

## 📁 โครงสร้างไฟล์ที่จะสร้าง

```
booking-app-demo-2025/
├── .github/
│   └── workflows/
│       ├── frontend-ci-cd.yml   ← Frontend CI/CD Pipeline
│       └── backend-ci-cd.yml    ← Backend CI/CD Pipeline
│
├── frontend/                    ← React + Vite App
│   ├── src/
│   │   └── __tests__/
│   │       ├── App.test.jsx          ← Unit Tests
│   │       ├── BookingForm.test.jsx  ← Component Tests
│   │       └── api.test.js           ← API Integration Tests
│   ├── .env.example             ← Environment Template
│   └── vite.config.js
│
├── backend/                     ← Node.js + Express API
│   ├── tests/
│   │   ├── unit/
│   │   │   └── bookingService.test.js
│   │   ├── integration/
│   │   │   └── bookingRoutes.test.js
│   │   └── security/
│   │       └── security.test.js ← Security Tests
│   ├── .env.example             ← Environment Template
│   └── server.js
│
├── nginx/
│   └── nginx.conf               ← NGINX Config (XSS Prevention)
│
└── scripts/
    └── security-check.sh        ← Security Check Script
```

---

## ✅ Checklist ก่อนเริ่มทดลอง

- [ ] มี GitHub Account และล็อกอินแล้ว
- [ ] Fork repository: `surachai-p/booking-app-demo-2025`
- [ ] มี Vercel Account (สมัครฟรีด้วย GitHub)
- [ ] มี Render Account (สมัครฟรีด้วย GitHub)
- [ ] ติดตั้ง Node.js ≥ 18 แล้ว
- [ ] ติดตั้ง Git แล้ว
- [ ] อ่าน [LAB-THEORY.md](docs/LAB-THEORY.md) แล้ว

---

## 👨‍🏫 ผู้จัดทำ

**วิชา:** CI/CD and DevOps Fundamentals  
**ปีการศึกษา:** 2025  
**Repository:** https://github.com/surachai-p/booking-app-demo-2025

---

> 💡 **เริ่มต้น:** อ่าน [📖 LAB-THEORY.md](docs/LAB-THEORY.md) ก่อนเสมอ!
