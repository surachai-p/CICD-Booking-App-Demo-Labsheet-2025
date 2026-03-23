# 🔧 LAB-02: Backend — Testing & Deploy to Render

[← LAB-01 Setup](LAB-01-SETUP.md) | [ถัดไป: LAB-03 Frontend →](LAB-03-FRONTEND.md)

---

## 🎯 เป้าหมาย

- เขียน Unit Tests และ Integration Tests สำหรับ Backend (Node.js/Express)
- ตั้งค่า ESLint และ Security Scanning
- สร้าง GitHub Actions Workflow สำหรับ Backend CI/CD
- Deploy อัตโนมัติไปยัง Render

---

## ขั้นตอนที่ 1: ติดตั้ง Testing Dependencies

```bash
cd backend

# Testing frameworks
npm install --save-dev jest supertest @jest/globals

# Coverage report
npm install --save-dev jest-coverage-badges

# Security testing
npm install --save-dev helmet express-rate-limit

# ESLint
npm install --save-dev eslint @eslint/js
```

### อัปเดต `package.json`

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --testPathPattern='tests/unit' --coverage",
    "test:integration": "jest --testPathPattern='tests/integration'",
    "test:security": "jest --testPathPattern='tests/security'",
    "test:all": "jest --coverage",
    "lint": "eslint src/ --ext .js",
    "lint:fix": "eslint src/ --ext .js --fix"
  },
  "jest": {
    "testEnvironment": "node",
    "coverageDirectory": "coverage",
    "coverageThreshold": {
      "global": {
        "branches": 70,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    },
    "collectCoverageFrom": [
      "src/**/*.js",
      "!src/**/*.test.js"
    ]
  }
}
```

---

## ขั้นตอนที่ 2: เขียน Unit Tests

สร้างไฟล์ `backend/tests/unit/bookingService.test.js`:

```javascript
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Unit Tests: Booking Service
// ทดสอบ business logic แยกจาก database และ HTTP layer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const { describe, test, expect, beforeEach, jest: jestObj } = require('@jest/globals');

// Mock database module เพื่อไม่ต้องเชื่อมต่อ DB จริง
jest.mock('../../src/db', () => ({
  query: jest.fn(),
}));

const db = require('../../src/db');
const bookingService = require('../../src/services/bookingService');

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
describe('BookingService — Unit Tests', () => {
  // รีเซ็ต mock ก่อนแต่ละ test
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ────────────────────────────────────────────────────────────
  describe('createBooking()', () => {

    test('✅ สร้าง booking สำเร็จด้วยข้อมูลถูกต้อง', async () => {
      // Arrange: เตรียมข้อมูล input และ mock return value
      const bookingData = {
        userId: 1,
        roomId: 101,
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        guests: 2,
      };
      const mockBooking = { id: 1, ...bookingData, status: 'confirmed' };
      db.query.mockResolvedValue({ rows: [mockBooking] });

      // Act: เรียกใช้ function ที่ทดสอบ
      const result = await bookingService.createBooking(bookingData);

      // Assert: ตรวจสอบผลลัพธ์
      expect(result).toEqual(mockBooking);
      expect(db.query).toHaveBeenCalledTimes(1);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO bookings'),
        expect.arrayContaining([1, 101, '2025-06-01', '2025-06-05', 2])
      );
    });

    test('❌ โยน error เมื่อ checkOut ก่อน checkIn', async () => {
      // Arrange: วันที่ไม่ถูกต้อง
      const invalidData = {
        userId: 1,
        roomId: 101,
        checkIn: '2025-06-05',
        checkOut: '2025-06-01',  // checkOut ก่อน checkIn
        guests: 2,
      };

      // Act & Assert: ต้องโยน error
      await expect(bookingService.createBooking(invalidData))
        .rejects.toThrow('Check-out date must be after check-in date');

      // Database ต้องไม่ถูกเรียก
      expect(db.query).not.toHaveBeenCalled();
    });

    test('❌ โยน error เมื่อจำนวนผู้เข้าพักเกินขีดจำกัด', async () => {
      const invalidData = {
        userId: 1,
        roomId: 101,
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        guests: 100,  // เกินขีดจำกัด
      };

      await expect(bookingService.createBooking(invalidData))
        .rejects.toThrow('Guests cannot exceed maximum capacity');
    });

    test('❌ โยน error เมื่อ database ล้มเหลว', async () => {
      const bookingData = {
        userId: 1,
        roomId: 101,
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        guests: 2,
      };
      db.query.mockRejectedValue(new Error('Connection refused'));

      await expect(bookingService.createBooking(bookingData))
        .rejects.toThrow('Connection refused');
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('getBookingById()', () => {

    test('✅ คืนค่า booking ที่ถูกต้องเมื่อพบ ID', async () => {
      const mockBooking = {
        id: 42,
        userId: 1,
        roomId: 101,
        status: 'confirmed',
      };
      db.query.mockResolvedValue({ rows: [mockBooking] });

      const result = await bookingService.getBookingById(42);

      expect(result).toEqual(mockBooking);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('SELECT'),
        [42]
      );
    });

    test('❌ โยน error เมื่อไม่พบ booking', async () => {
      db.query.mockResolvedValue({ rows: [] });

      await expect(bookingService.getBookingById(999))
        .rejects.toThrow('Booking not found');
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('calculateTotalPrice()', () => {

    test('✅ คำนวณราคาถูกต้องสำหรับ 4 คืน', () => {
      const result = bookingService.calculateTotalPrice({
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        pricePerNight: 1500,
      });

      expect(result).toBe(6000);  // 4 คืน × 1500 บาท
    });

    test('✅ คำนวณราคาถูกต้องสำหรับ 1 คืน', () => {
      const result = bookingService.calculateTotalPrice({
        checkIn: '2025-06-01',
        checkOut: '2025-06-02',
        pricePerNight: 2500,
      });

      expect(result).toBe(2500);
    });

    test('❌ โยน error เมื่อ pricePerNight ไม่ถูกต้อง', () => {
      expect(() => bookingService.calculateTotalPrice({
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        pricePerNight: -100,
      })).toThrow('Price per night must be positive');
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('cancelBooking()', () => {

    test('✅ ยกเลิก booking สำเร็จ', async () => {
      const mockBooking = { id: 1, status: 'confirmed' };
      const mockCancelled = { id: 1, status: 'cancelled' };

      db.query
        .mockResolvedValueOnce({ rows: [mockBooking] })   // getById
        .mockResolvedValueOnce({ rows: [mockCancelled] }); // update

      const result = await bookingService.cancelBooking(1, 1);

      expect(result.status).toBe('cancelled');
    });

    test('❌ ไม่สามารถยกเลิก booking ที่ cancelled แล้ว', async () => {
      db.query.mockResolvedValue({ rows: [{ id: 1, status: 'cancelled' }] });

      await expect(bookingService.cancelBooking(1, 1))
        .rejects.toThrow('Booking is already cancelled');
    });
  });
});
```

---

## ขั้นตอนที่ 3: เขียน Integration Tests

สร้างไฟล์ `backend/tests/integration/bookingRoutes.test.js`:

```javascript
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Integration Tests: Booking API Routes
// ทดสอบ HTTP endpoints ด้วย Supertest (ไม่ต้องรัน server จริง)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const request = require('supertest');
const app = require('../../src/app');
const db = require('../../src/db');

// Mock database
jest.mock('../../src/db');

// Mock JWT authentication middleware
jest.mock('../../src/middleware/auth', () => ({
  authenticate: (req, res, next) => {
    req.user = { id: 1, email: 'test@example.com', role: 'user' };
    next();
  },
}));

describe('Booking API Routes — Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ────────────────────────────────────────────────────────────
  describe('POST /api/bookings', () => {

    const validBookingPayload = {
      roomId: 101,
      checkIn: '2025-06-01',
      checkOut: '2025-06-05',
      guests: 2,
    };

    test('✅ 201 — สร้าง booking สำเร็จ', async () => {
      // Mock DB response
      db.query.mockResolvedValue({
        rows: [{
          id: 1,
          userId: 1,
          ...validBookingPayload,
          status: 'confirmed',
          totalPrice: 6000,
          createdAt: new Date().toISOString(),
        }],
      });

      const response = await request(app)
        .post('/api/bookings')
        .send(validBookingPayload)
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(201);
      expect(response.body).toMatchObject({
        success: true,
        data: {
          id: 1,
          status: 'confirmed',
        },
      });
    });

    test('❌ 400 — ส่งข้อมูลไม่ครบ', async () => {
      const response = await request(app)
        .post('/api/bookings')
        .send({ roomId: 101 })  // ขาด checkIn, checkOut
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    test('❌ 401 — ไม่ได้ authenticate', async () => {
      // Override mock to simulate unauthenticated
      const response = await request(app)
        .post('/api/bookings')
        .send(validBookingPayload);
        // ไม่ส่ง Authorization header

      expect(response.status).toBe(401);
    });

    test('❌ 422 — วันที่ไม่ถูกต้อง', async () => {
      const response = await request(app)
        .post('/api/bookings')
        .send({
          ...validBookingPayload,
          checkIn: '2025-06-05',
          checkOut: '2025-06-01',  // checkOut ก่อน checkIn
        })
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(422);
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('GET /api/bookings/:id', () => {

    test('✅ 200 — คืนค่า booking ที่ถูกต้อง', async () => {
      db.query.mockResolvedValue({
        rows: [{
          id: 1,
          userId: 1,
          roomId: 101,
          status: 'confirmed',
        }],
      });

      const response = await request(app)
        .get('/api/bookings/1')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.id).toBe(1);
    });

    test('❌ 404 — ไม่พบ booking', async () => {
      db.query.mockResolvedValue({ rows: [] });

      const response = await request(app)
        .get('/api/bookings/999')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });

    test('❌ 400 — ID ไม่ถูกต้อง (ไม่ใช่ตัวเลข)', async () => {
      const response = await request(app)
        .get('/api/bookings/abc')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(400);
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('DELETE /api/bookings/:id', () => {

    test('✅ 200 — ยกเลิก booking สำเร็จ', async () => {
      db.query
        .mockResolvedValueOnce({ rows: [{ id: 1, userId: 1, status: 'confirmed' }] })
        .mockResolvedValueOnce({ rows: [{ id: 1, status: 'cancelled' }] });

      const response = await request(app)
        .delete('/api/bookings/1')
        .set('Authorization', 'Bearer test-token');

      expect(response.status).toBe(200);
      expect(response.body.data.status).toBe('cancelled');
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('Response Format', () => {

    test('✅ Response มี CORS headers ถูกต้อง', async () => {
      const response = await request(app)
        .get('/api/health');

      expect(response.headers['access-control-allow-origin']).toBeDefined();
    });

    test('✅ Response มี Content-Type: application/json', async () => {
      const response = await request(app)
        .get('/api/health');

      expect(response.headers['content-type']).toMatch(/application\/json/);
    });
  });
});
```

---

## ขั้นตอนที่ 4: เขียน Security Tests

สร้างไฟล์ `backend/tests/security/security.test.js`:

```javascript
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Security Tests: ทดสอบ Security Headers & Vulnerabilities
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const request = require('supertest');
const app = require('../../src/app');

describe('Security Tests', () => {

  // ────────────────────────────────────────────────────────────
  describe('Security Headers (Helmet.js)', () => {

    let response;
    beforeAll(async () => {
      response = await request(app).get('/api/health');
    });

    test('✅ มี X-Content-Type-Options: nosniff', () => {
      expect(response.headers['x-content-type-options']).toBe('nosniff');
    });

    test('✅ มี X-Frame-Options', () => {
      expect(response.headers['x-frame-options']).toBeDefined();
    });

    test('✅ มี X-XSS-Protection', () => {
      // Helmet 7+ ไม่ส่ง header นี้แล้ว แต่ CSP ทดแทน
      // ตรวจสอบว่ามี Content-Security-Policy แทน
      const csp = response.headers['content-security-policy'];
      expect(csp).toBeDefined();
    });

    test('✅ ไม่เปิดเผย X-Powered-By', () => {
      expect(response.headers['x-powered-by']).toBeUndefined();
    });

    test('✅ มี Strict-Transport-Security (HSTS)', () => {
      expect(response.headers['strict-transport-security']).toBeDefined();
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('SQL Injection Prevention', () => {

    test('✅ ป้องกัน SQL Injection ใน booking ID', async () => {
      const maliciousId = "1; DROP TABLE bookings; --";

      const response = await request(app)
        .get(`/api/bookings/${encodeURIComponent(maliciousId)}`)
        .set('Authorization', 'Bearer valid-token');

      // ต้องได้รับ 400 Bad Request ไม่ใช่ 500
      expect(response.status).toBe(400);
      expect(response.status).not.toBe(500);
    });

    test('✅ ป้องกัน SQL Injection ใน query parameters', async () => {
      const response = await request(app)
        .get("/api/rooms?search=' OR '1'='1")
        .set('Authorization', 'Bearer valid-token');

      expect(response.status).not.toBe(500);
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('XSS Prevention', () => {

    test('✅ Sanitize HTML ใน request body', async () => {
      const xssPayload = {
        roomId: 101,
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        guests: 2,
        notes: '<script>alert("XSS")</script>',  // XSS payload
      };

      const response = await request(app)
        .post('/api/bookings')
        .send(xssPayload)
        .set('Authorization', 'Bearer valid-token');

      // ถ้า booking ถูกสร้าง notes ต้องถูก sanitize แล้ว
      if (response.status === 201 && response.body.data?.notes) {
        expect(response.body.data.notes).not.toContain('<script>');
        expect(response.body.data.notes).not.toContain('alert');
      }
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('Rate Limiting', () => {

    test('✅ Rate limit ทำงานสำหรับ API endpoints', async () => {
      // ส่ง request มากกว่า limit
      const requests = Array(110).fill(null).map(() =>
        request(app).get('/api/health')
      );

      const responses = await Promise.all(requests);
      const tooManyRequests = responses.some(r => r.status === 429);

      // อย่างน้อยบางส่วนต้องได้รับ 429
      expect(tooManyRequests).toBe(true);
    }, 30000); // timeout 30s
  });

  // ────────────────────────────────────────────────────────────
  describe('Authentication Security', () => {

    test('✅ Reject invalid JWT token', async () => {
      const response = await request(app)
        .get('/api/bookings/1')
        .set('Authorization', 'Bearer invalid.jwt.token');

      expect(response.status).toBe(401);
    });

    test('✅ Reject expired JWT token', async () => {
      // expired token (ทดสอบด้วย token ที่หมดอายุแล้ว)
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImV4cCI6MTYwMDAwMDAwMH0.invalid';
      const response = await request(app)
        .get('/api/bookings/1')
        .set('Authorization', `Bearer ${expiredToken}`);

      expect(response.status).toBe(401);
    });

    test('✅ Reject missing Authorization header', async () => {
      const response = await request(app)
        .get('/api/bookings/1');  // ไม่มี Authorization header

      expect(response.status).toBe(401);
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('CORS Configuration', () => {

    test('✅ อนุญาต request จาก frontend origin', async () => {
      const response = await request(app)
        .get('/api/health')
        .set('Origin', process.env.CORS_ORIGIN || 'http://localhost:5173');

      expect(response.headers['access-control-allow-origin']).toBeDefined();
    });

    test('✅ ปฏิเสธ request จาก origin ที่ไม่รู้จัก', async () => {
      const response = await request(app)
        .get('/api/health')
        .set('Origin', 'https://malicious-site.com');

      // อาจไม่มี CORS header หรือ origin ไม่ตรง
      const origin = response.headers['access-control-allow-origin'];
      if (origin) {
        expect(origin).not.toBe('https://malicious-site.com');
      }
    });
  });
});
```

---

## ขั้นตอนที่ 5: สร้าง GitHub Actions Workflow (Backend)

สร้างไฟล์ `.github/workflows/backend-ci-cd.yml`:

```yaml
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Backend CI/CD Pipeline
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
name: 🔧 Backend CI/CD

# ─── Triggers ──────────────────────────────────────────────────
on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'            # รันเฉพาะเมื่อไฟล์ใน backend/ เปลี่ยน
      - '.github/workflows/backend-ci-cd.yml'
  pull_request:
    branches: [main]
    paths:
      - 'backend/**'

# ─── Global Variables ──────────────────────────────────────────
env:
  NODE_VERSION: '18'
  WORKING_DIR: ./backend

# ─── Prevent duplicate runs ────────────────────────────────────
concurrency:
  group: backend-${{ github.ref }}
  cancel-in-progress: true

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jobs:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  # ────────────────────────────────────────────────────────────
  # JOB 1: Lint
  # ────────────────────────────────────────────────────────────
  lint:
    name: 🔍 ESLint Check
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ⚙️ Setup Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🔍 Run ESLint
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run lint

  # ────────────────────────────────────────────────────────────
  # JOB 2: Unit Tests
  # ────────────────────────────────────────────────────────────
  unit-tests:
    name: 🧪 Unit Tests
    runs-on: ubuntu-latest
    needs: lint                # รอให้ lint ผ่านก่อน

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ⚙️ Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🧪 Run Unit Tests
        working-directory: ${{ env.WORKING_DIR }}
        run: npm test -- --coverage
        env:
          NODE_ENV: test

      - name: 📊 Upload Coverage Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: backend-coverage
          path: backend/coverage/
          retention-days: 7

  # ────────────────────────────────────────────────────────────
  # JOB 3: Integration Tests
  # ────────────────────────────────────────────────────────────
  integration-tests:
    name: 🔗 Integration Tests
    runs-on: ubuntu-latest
    needs: lint

    services:
      # PostgreSQL สำหรับ integration tests
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpassword
          POSTGRES_DB: booking_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ⚙️ Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🗄️ Run Database Migrations
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run db:migrate
        env:
          DATABASE_URL: postgresql://testuser:testpassword@localhost:5432/booking_test

      - name: 🔗 Run Integration Tests
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run test:integration
        env:
          NODE_ENV: test
          DATABASE_URL: postgresql://testuser:testpassword@localhost:5432/booking_test
          JWT_SECRET: test-secret-key-for-ci-only
          CORS_ORIGIN: http://localhost:5173

  # ────────────────────────────────────────────────────────────
  # JOB 4: Security Tests
  # ────────────────────────────────────────────────────────────
  security-tests:
    name: 🔒 Security Tests
    runs-on: ubuntu-latest
    needs: lint

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ⚙️ Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🔒 Run Security Tests
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run test:security
        env:
          NODE_ENV: test
          JWT_SECRET: test-secret-key-for-ci-only
          CORS_ORIGIN: http://localhost:5173

      - name: 🛡️ Scan for Vulnerabilities (npm audit)
        working-directory: ${{ env.WORKING_DIR }}
        run: |
          echo "=== npm audit ===" 
          npm audit --audit-level=high
        # audit-level=high: fail เฉพาะ high/critical vulnerabilities

      - name: 🔍 Check for Secrets in Code
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./backend
          base: ${{ github.event.repository.default_branch }}
          head: HEAD

  # ────────────────────────────────────────────────────────────
  # JOB 5: Deploy to Render (เฉพาะ main branch)
  # ────────────────────────────────────────────────────────────
  deploy:
    name: 🚀 Deploy to Render
    runs-on: ubuntu-latest
    needs: [unit-tests, integration-tests, security-tests]  # ต้องผ่านทุก tests
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    environment:
      name: production
      url: ${{ steps.get-url.outputs.url }}

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🚀 Trigger Render Deploy
        id: deploy
        run: |
          echo "Triggering Render deployment..."
          RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "${{ secrets.RENDER_DEPLOY_HOOK_URL }}")
          
          if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "201" ]; then
            echo "✅ Deployment triggered successfully (HTTP $RESPONSE)"
          else
            echo "❌ Deployment failed (HTTP $RESPONSE)"
            exit 1
          fi

      - name: ⏳ Wait for Render to Deploy
        run: |
          echo "Waiting 90 seconds for Render to deploy..."
          sleep 90

      - name: 🔍 Health Check
        id: get-url
        run: |
          BACKEND_URL="${{ secrets.RENDER_BACKEND_URL }}"
          echo "url=$BACKEND_URL" >> $GITHUB_OUTPUT
          
          echo "Checking health at $BACKEND_URL/api/health"
          
          for i in {1..5}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/health")
            if [ "$STATUS" = "200" ]; then
              echo "✅ Health check passed (attempt $i)"
              exit 0
            fi
            echo "⏳ Attempt $i failed (HTTP $STATUS), waiting 30s..."
            sleep 30
          done
          
          echo "❌ Health check failed after 5 attempts"
          exit 1

      - name: 📢 Notify Deployment Success
        if: success()
        run: |
          echo "🎉 Backend deployed successfully!"
          echo "URL: ${{ secrets.RENDER_BACKEND_URL }}"
          echo "Commit: ${{ github.sha }}"
          echo "By: ${{ github.actor }}"
```

---

## ขั้นตอนที่ 6: ทดสอบ Workflow

```bash
# Commit และ push เพื่อ trigger workflow
git add backend/ .github/workflows/backend-ci-cd.yml
git commit -m "feat: add backend tests and CI/CD workflow"
git push origin main

# ดู workflow ใน GitHub
# → Repository → Actions → Backend CI/CD
```

---

## ✅ Checklist

- [ ] ติดตั้ง testing dependencies แล้ว
- [ ] เขียน unit tests อย่างน้อย 8 test cases
- [ ] เขียน integration tests อย่างน้อย 5 test cases
- [ ] เขียน security tests อย่างน้อย 5 test cases
- [ ] สร้าง `backend-ci-cd.yml` workflow แล้ว
- [ ] Push ขึ้น GitHub และ workflow รันสำเร็จ
- [ ] Deploy ไป Render สำเร็จ (green checkmark ทุก job)

---

[← LAB-01 Setup](LAB-01-SETUP.md) | [ถัดไป: LAB-03 Frontend →](LAB-03-FRONTEND.md)
