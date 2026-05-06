# 🚀 Lab Workbook: CI/CD with booking-app-demo-2025

> **Reference Repository:** `https://github.com/surachai-p/booking-app-demo-2025`
> **ระดับ:** ปริญญาตรี / ปริญญาโท
> **เวลา:** 4–5 ชั่วโมง

---

## 🗂️ สารบัญใบงาน

| ไฟล์ | หัวข้อ | เวลา |
|------|--------|------|
| [📖 LAB-THEORY.md](LAB-THEORY.md) | ทฤษฎี GitHub Actions & CI/CD | อ่านก่อนทดลอง |
| [⚙️ LAB-01-SETUP.md](LAB-01-SETUP.md) | เตรียม Repository, Backend, Frontend และ Deployment | 120 นาที |
| [🔒 LAB-04-SECURITY.md](LAB-04-SECURITY.md) | Security Review & Deployment Hardening | 45 นาที |
| [📝 LAB-ASSIGNMENT.md](LAB-ASSIGNMENT.md) | ใบงานส่ง & คำถาม | ส่งท้ายคาบ |

---

## 🎯 วัตถุประสงค์การทดลอง

หลังจากทดลองเสร็จ นักศึกษาจะสามารถ:

1. **อธิบาย** กระบวนการ CI/CD ของ GitHub Actions ได้
2. **ตั้งค่า** Self-hosted runner และ workflow ใน `.github/workflows/ci.yml`
3. **ติดตั้ง** Backend (PostgreSQL + Prisma) และ Frontend (React + Vite)
4. **รัน** Newman API tests และ Robot UI tests
5. **สร้าง** environment files และตั้งค่า secrets อย่างปลอดภัย
6. **Deploy** Frontend ไป Vercel และ Backend ไป Render แบบอัตโนมัติ

---

## 📐 สถาปัตยกรรมระบบ

```
┌─────────────────────────────────────────────────────────────────┐
│                       Developer Workstation                    │
│  ┌─────────────┐   git push   ┌──────────────────────────────┐  │
│  │  Source Code │ ──────────▶  │      GitHub Repository       │  │
│  └─────────────┘              │  booking-app-demo-2025        │  │
└──────────────────────────────│──────────────────────────────│──┘
                                └──────────────────────────────┘
                                           │
                          ┌────────────────┴────────────────┐
                          │     GitHub Actions CI Workflow   │
                          │       (.github/workflows/ci.yml) │
                          └────────────────┬────────────────┘
                                           │
                    ┌─────────────┐      ┌───────────────┐
                    │  Self-hosted │      │  GitHub-hosted │
                    │    Runner    │      │  optional      │
                    └──────┬───────┘      └──────┬────────┘
                           │                     │
             ┌─────────────▼─────────────┐   ┌────▼────┐
             │       Backend Service      │   │ Vercel  │
             │ Node.js + Express + Prisma │   │ Frontend │
             │     + PostgreSQL / Docker  │   │ React + Vite │
             └─────────────┬──────────────┘   └──────────┘
                           │
                     ┌─────▼─────┐
                     │ End Users │
                     │  (Browser)│
                     └───────────┘
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

## 🗓️ กระบวนการ CI/CD ที่จะเรียนรู้

```
git push
    │
    └──▶ [ GitHub Actions CI ]
              │
              ├─ ✅ Checkout repository
              ├─ ✅ Setup Node.js
              ├─ ✅ Install backend dependencies
              ├─ ✅ Start PostgreSQL (Docker Compose)
              ├─ ✅ Generate Prisma client
              ├─ ✅ Run backend migrations
              ├─ ✅ Install frontend dependencies
              ├─ ✅ Build frontend
              ├─ ✅ Deploy to Vercel & Render
              └─ ✅ Report workflow status
```

---

## 📁 โครงสร้างไฟล์หลักของโครงการ

```
booking-app-demo-2025/
├── .github/
│   └── workflows/
│       └── ci.yml
├── backend/
│   ├── docker-compose.yml
│   ├── package.json
│   ├── prisma/
│   │   └── schema.prisma
│   ├── server.js
│   ├── database.js
│   └── .env.example
├── frontend/
│   ├── package.json
│   ├── vite.config.js
│   ├── tailwind.config.js
│   └── .env.example
├── newman/
│   ├── hotel-booking-collection.json
│   ├── hotel-booking-env.json
├── tests/
│   └── robot/
│       └── hotel_booking_test.robot
├── package.json
└── README.md
```

---

## ✅ Checklist ก่อนเริ่มทดลอง

- [ ] Fork repository: `surachai-p/booking-app-demo-2025`
- [ ] Clone repository ลงเครื่อง
- [ ] สร้าง `backend/.env` และ `frontend/.env`
- [ ] ติดตั้ง dependencies ทั้ง root/backend/frontend
- [ ] รัน `docker compose up -d` ใน `backend`
- [ ] ตรวจสอบ `.github/workflows/ci.yml`
- [ ] ตั้งค่า GitHub Secrets ตามที่จำเป็น
- [ ] ตรวจสอบว่า frontend และ backend ทำงานได้บน local

---

## 👨‍🏫 ผู้จัดทำ

**วิชา:** CI/CD and DevOps Fundamentals  
**ปีการศึกษา:** 2025  
**Repository:** https://github.com/surachai-p/booking-app-demo-2025

---

> 💡 **เริ่มต้น:** อ่าน [📖 LAB-THEORY.md](docs/LAB-THEORY.md) ก่อนเสมอ!
