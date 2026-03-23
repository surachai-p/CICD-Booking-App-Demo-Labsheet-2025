# 📝 LAB-ASSIGNMENT: ใบงานส่ง CI/CD Pipeline

[← LAB-04 Security](LAB-04-SECURITY.md) | [กลับ README](../README.md)

---

## ข้อมูลนักศึกษา

```
ชื่อ-นามสกุล : ________________________________________
รหัสนักศึกษา : ________________________________________
กลุ่ม         : ________________________________________
วันที่ทดลอง   : ________________________________________
GitHub URL    : https://github.com/___________________/booking-app-demo-2025
Vercel URL    : https://_____________________________.vercel.app
Render URL    : https://_____________________________.onrender.com
```

---

## ส่วนที่ 1: ภาพหน้าจอ (รวม 30 คะแนน)

> 📸 แนบภาพหน้าจอของแต่ละขั้นตอน พร้อมคำอธิบายสั้นๆ

### 1.1 GitHub Actions Workflow (15 คะแนน)

**ภาพที่ 1:** แสดง GitHub Actions dashboard ที่มี workflow สีเขียว (ทั้ง frontend และ backend)
```
[แนบรูปที่นี่]

คำอธิบาย: _______________________________________________
```

**ภาพที่ 2:** แสดงรายละเอียด Jobs ของ Backend Workflow (lint → unit-tests → integration-tests → security-tests → deploy)
```
[แนบรูปที่นี่]

คำอธิบาย: _______________________________________________
```

**ภาพที่ 3:** แสดงรายละเอียด Jobs ของ Frontend Workflow (lint → unit-tests → integration-tests → build → deploy)
```
[แนบรูปที่นี่]

คำอธิบาย: _______________________________________________
```

### 1.2 Test Results (10 คะแนน)

**ภาพที่ 4:** ผลลัพธ์การรัน Backend Tests (ต้องเห็น test cases และ coverage)
```
[แนบรูปที่นี่]

จำนวน test ที่ผ่าน: _______ / _______ tests
Coverage: _______% lines
```

**ภาพที่ 5:** ผลลัพธ์การรัน Frontend Tests (Vitest)
```
[แนบรูปที่นี่]

จำนวน test ที่ผ่าน: _______ / _______ tests
Coverage: _______% lines
```

### 1.3 Deployment (5 คะแนน)

**ภาพที่ 6:** แสดง Vercel deployment ที่สำเร็จ (มี URL และ status: Ready)
```
[แนบรูปที่นี่]
```

**ภาพที่ 7:** แสดง Render deployment ที่สำเร็จ (สีเขียว + health check ผ่าน)
```
[แนบรูปที่นี่]
```

---

## ส่วนที่ 2: คำถามทฤษฎี (30 คะแนน)

### คำถามที่ 1 (5 คะแนน)
**อธิบายความแตกต่างระหว่าง `on: push` กับ `on: pull_request` และยกตัวอย่างว่าควรใช้แต่ละอันเมื่อไหร่**

```
คำตอบ:




```

---

### คำถามที่ 2 (5 คะแนน)
**ในไฟล์ workflow ต่อไปนี้ job `deploy` จะรันหรือไม่ ในแต่ละกรณี? อธิบายเหตุผล**

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

| กรณี | จะรัน deploy หรือไม่ | เหตุผล |
|-----|---------------------|--------|
| Push ไป `main` และ test ผ่าน | | |
| Push ไป `main` และ test ไม่ผ่าน | | |
| Push ไป `develop` และ test ผ่าน | | |
| สร้าง PR ไป `main` และ test ผ่าน | | |

---

### คำถามที่ 3 (5 คะแนน)
**ทำไมถึงต้องใช้ GitHub Secrets แทนการเขียน API key ตรงๆ ใน workflow file? และมีวิธีใดที่ทำให้ secret leak ได้โดยไม่ตั้งใจ?**

```
คำตอบ:




```

---

### คำถามที่ 4 (5 คะแนน)
**อธิบายว่า `concurrency` ใน workflow ทำงานอย่างไร และมีประโยชน์อะไร?**

```yaml
concurrency:
  group: backend-${{ github.ref }}
  cancel-in-progress: true
```

```
คำตอบ:




```

---

### คำถามที่ 5 (5 คะแนน)
**อธิบายหลักการของ Testing Pyramid และในการทดลองนี้ แต่ละ layer ทดสอบอะไรบ้าง?**

```
คำตอบ:

Unit Tests ทดสอบ:

Integration Tests ทดสอบ:

Security Tests ทดสอบ:

```

---

### คำถามที่ 6 (5 คะแนน)
**XSS (Cross-Site Scripting) คืออะไร และ NGINX ป้องกันอย่างไร? ยกตัวอย่าง header ที่ใช้ป้องกัน**

```
คำตอบ:




```

---

## ส่วนที่ 3: การวิเคราะห์โค้ด (20 คะแนน)

### คำถามที่ 7 (10 คะแนน)
**เลือก test case จาก backend ที่คุณเขียน มา 2 test case แล้วอธิบาย:**
- ทดสอบอะไร (What)
- ทดสอบอย่างไร (How: Arrange-Act-Assert)
- ทำไมถึงสำคัญ (Why)

**Test Case ที่ 1:**
```javascript
// [วางโค้ด test case ที่นี่]
```

```
อธิบาย:
- ทดสอบอะไร: 
- Arrange (เตรียมข้อมูล): 
- Act (รัน function): 
- Assert (ตรวจสอบผล): 
- ทำไมสำคัญ: 
```

**Test Case ที่ 2:**
```javascript
// [วางโค้ด test case ที่นี่]
```

```
อธิบาย:
- ทดสอบอะไร: 
- Arrange: 
- Act: 
- Assert: 
- ทำไมสำคัญ: 
```

---

### คำถามที่ 8 (10 คะแนน)
**วิเคราะห์ workflow ต่อไปนี้: มีปัญหาอะไรบ้าง และแก้ไขอย่างไร?**

```yaml
name: Deploy

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy
        run: |
          curl -X POST https://api.render.com/deploy/srv-xxx \
            -H "Authorization: Bearer rnd_xxxxxxxxxxxxx"
```

```
ปัญหาที่พบ:
1. 
2. 
3. 

วิธีแก้ไข:
1. 
2. 
3. 

โค้ดที่แก้ไขแล้ว:
```

---

## ส่วนที่ 4: สรุปการทดลอง (20 คะแนน)

### 4.1 สิ่งที่ได้เรียนรู้ (10 คะแนน)

**อธิบายอย่างน้อย 5 สิ่งที่ได้เรียนรู้จากการทดลองนี้:**

```
1. 

2. 

3. 

4. 

5. 
```

### 4.2 ปัญหาที่พบและวิธีแก้ (5 คะแนน)

```
ปัญหาที่พบระหว่างทดลอง:


วิธีแก้ไข:


```

### 4.3 ข้อเสนอแนะ (5 คะแนน)

**ถ้าจะพัฒนาระบบ CI/CD นี้ต่อไป คุณจะเพิ่มอะไร?**

```
ข้อเสนอแนะ:


```

---

## เกณฑ์การให้คะแนน

| ส่วน | คะแนนเต็ม | คะแนนที่ได้ |
|-----|---------|----------|
| ส่วนที่ 1: ภาพหน้าจอ | 30 | |
| ส่วนที่ 2: คำถามทฤษฎี | 30 | |
| ส่วนที่ 3: การวิเคราะห์โค้ด | 20 | |
| ส่วนที่ 4: สรุปการทดลอง | 20 | |
| **รวม** | **100** | |

### เกณฑ์ Bonus (เพิ่มเติม สูงสุด 10 คะแนน)

| งาน | คะแนน |
|-----|------|
| เพิ่ม E2E Tests ด้วย Playwright | +5 |
| ตั้งค่า Environment Protection Rules (manual approval) | +3 |
| สร้าง GitHub Status Badge ใน README | +2 |

---

## วิธีส่งงาน

1. **Push ทุกไฟล์ขึ้น GitHub** (fork repository ของคุณ)
2. **ส่ง GitHub Repository URL** ผ่านระบบส่งงาน
3. **ตรวจสอบ:** GitHub Actions ต้องแสดงสีเขียวทั้งหมด ณ เวลาส่ง

```bash
# ตรวจสอบก่อนส่ง
git status           # ต้องไม่มี uncommitted changes
git log --oneline -5 # แสดง commits ล่าสุด
```

---

> 🏆 **ขอให้โชคดี!** หากมีปัญหา ให้ถามอาจารย์หรือตรวจสอบเอกสารที่ [docs/LAB-THEORY.md](LAB-THEORY.md)
