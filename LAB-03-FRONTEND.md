# 🎨 LAB-03: Frontend — Testing & Deploy to Vercel

[← LAB-02 Backend](LAB-02-BACKEND.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)

---

## 🎯 เป้าหมาย

- เขียน Unit Tests และ Integration Tests สำหรับ React components
- ทดสอบ API integration ด้วย Mock Service Worker (MSW)
- สร้าง GitHub Actions Workflow สำหรับ Frontend CI/CD
- Deploy อัตโนมัติไปยัง Vercel

---

## ขั้นตอนที่ 1: ติดตั้ง Testing Dependencies

```bash
cd frontend

# Vitest — faster than Jest สำหรับ Vite projects
npm install --save-dev vitest @vitest/coverage-v8 @vitest/ui

# React Testing Library
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event

# Mock Service Worker — mock API calls
npm install --save-dev msw

# jsdom — browser environment สำหรับ Node.js
npm install --save-dev jsdom
```

### อัปเดต `package.json`

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:ui": "vitest --ui",
    "test:integration": "vitest run --testPathPattern='integration'",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives"
  }
}
```

### อัปเดต `vite.config.js`

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  
  // ─── Test Configuration ────────────────────────────────────
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.js'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 75,
        functions: 75,
        branches: 70,
        statements: 75,
      },
      exclude: [
        'node_modules/',
        'src/test-setup.js',
        '**/*.config.*',
        '**/types/**',
      ],
    },
  },
});
```

### สร้าง Test Setup File

สร้างไฟล์ `frontend/src/test-setup.js`:

```javascript
// ─── Import Jest DOM matchers ──────────────────────────────────
import '@testing-library/jest-dom';

// ─── Mock window.matchMedia ────────────────────────────────────
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});

// ─── Mock IntersectionObserver ────────────────────────────────
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  disconnect() {}
  observe() {}
  unobserve() {}
};

// ─── Suppress console.error ใน tests ──────────────────────────
const originalError = console.error;
beforeAll(() => {
  console.error = (...args) => {
    if (/Warning.*not wrapped in act/i.test(args[0])) return;
    originalError.call(console, ...args);
  };
});
afterAll(() => {
  console.error = originalError;
});
```

---

## ขั้นตอนที่ 2: เขียน Component Unit Tests

สร้างไฟล์ `frontend/src/__tests__/BookingForm.test.jsx`:

```jsx
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Unit Tests: BookingForm Component
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { describe, test, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import BookingForm from '../components/BookingForm';

// Mock API service
vi.mock('../services/bookingApi', () => ({
  createBooking: vi.fn(),
}));

import { createBooking } from '../services/bookingApi';

// ─── Helper: render with minimal props ────────────────────────
const defaultProps = {
  roomId: 101,
  roomName: 'Deluxe Room',
  pricePerNight: 1500,
  onSuccess: vi.fn(),
  onError: vi.fn(),
};

const renderBookingForm = (props = {}) =>
  render(<BookingForm {...defaultProps} {...props} />);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
describe('BookingForm Component', () => {
  const user = userEvent.setup();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  // ────────────────────────────────────────────────────────────
  describe('Rendering', () => {

    test('✅ แสดง form fields ทั้งหมด', () => {
      renderBookingForm();

      expect(screen.getByLabelText(/check-in/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/check-out/i)).toBeInTheDocument();
      expect(screen.getByLabelText(/guests/i)).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /book now/i })).toBeInTheDocument();
    });

    test('✅ แสดงชื่อห้องและราคาต่อคืน', () => {
      renderBookingForm();

      expect(screen.getByText('Deluxe Room')).toBeInTheDocument();
      expect(screen.getByText(/1,500/)).toBeInTheDocument();
    });

    test('✅ ปุ่ม Submit disabled เมื่อยังไม่กรอกข้อมูล', () => {
      renderBookingForm();

      const submitButton = screen.getByRole('button', { name: /book now/i });
      expect(submitButton).toBeDisabled();
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('Form Validation', () => {

    test('✅ แสดง error เมื่อไม่ได้เลือกวันที่', async () => {
      renderBookingForm();

      const submitButton = screen.getByRole('button', { name: /book now/i });
      await user.click(submitButton);

      expect(await screen.findByText(/check-in date is required/i)).toBeInTheDocument();
    });

    test('✅ แสดง error เมื่อ check-out ก่อน check-in', async () => {
      renderBookingForm();

      await user.type(screen.getByLabelText(/check-in/i), '2025-06-05');
      await user.type(screen.getByLabelText(/check-out/i), '2025-06-01');
      await user.click(screen.getByRole('button', { name: /book now/i }));

      expect(await screen.findByText(/check-out must be after check-in/i))
        .toBeInTheDocument();
    });

    test('✅ แสดง error เมื่อจำนวนแขกน้อยกว่า 1', async () => {
      renderBookingForm();

      await user.type(screen.getByLabelText(/check-in/i), '2025-06-01');
      await user.type(screen.getByLabelText(/check-out/i), '2025-06-05');
      await user.clear(screen.getByLabelText(/guests/i));
      await user.type(screen.getByLabelText(/guests/i), '0');

      expect(await screen.findByText(/at least 1 guest required/i))
        .toBeInTheDocument();
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('Price Calculation', () => {

    test('✅ คำนวณราคารวมอัตโนมัติเมื่อเลือกวันที่', async () => {
      renderBookingForm();

      await user.type(screen.getByLabelText(/check-in/i), '2025-06-01');
      await user.type(screen.getByLabelText(/check-out/i), '2025-06-05');

      // 4 คืน × 1,500 = 6,000
      expect(await screen.findByText(/total.*6,000/i)).toBeInTheDocument();
    });

    test('✅ อัปเดตราคาเมื่อเปลี่ยนวันที่', async () => {
      renderBookingForm();

      await user.type(screen.getByLabelText(/check-in/i), '2025-06-01');
      await user.type(screen.getByLabelText(/check-out/i), '2025-06-03');
      // 2 คืน × 1,500 = 3,000

      await user.clear(screen.getByLabelText(/check-out/i));
      await user.type(screen.getByLabelText(/check-out/i), '2025-06-06');
      // 5 คืน × 1,500 = 7,500

      expect(await screen.findByText(/total.*7,500/i)).toBeInTheDocument();
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('Form Submission', () => {

    const fillForm = async () => {
      await user.type(screen.getByLabelText(/check-in/i), '2025-06-01');
      await user.type(screen.getByLabelText(/check-out/i), '2025-06-05');
      await user.clear(screen.getByLabelText(/guests/i));
      await user.type(screen.getByLabelText(/guests/i), '2');
    };

    test('✅ Submit สำเร็จ — เรียก onSuccess callback', async () => {
      createBooking.mockResolvedValue({ id: 1, status: 'confirmed' });
      renderBookingForm();

      await fillForm();
      await user.click(screen.getByRole('button', { name: /book now/i }));

      await waitFor(() => {
        expect(defaultProps.onSuccess).toHaveBeenCalledWith({
          id: 1,
          status: 'confirmed',
        });
      });
    });

    test('✅ แสดง loading state ระหว่าง submit', async () => {
      createBooking.mockImplementation(() =>
        new Promise(resolve => setTimeout(() => resolve({ id: 1 }), 100))
      );
      renderBookingForm();

      await fillForm();
      await user.click(screen.getByRole('button', { name: /book now/i }));

      // ปุ่มควรเปลี่ยนเป็น loading state
      expect(screen.getByRole('button', { name: /booking.../i })).toBeInTheDocument();
      expect(screen.getByRole('button')).toBeDisabled();

      await waitFor(() => {
        expect(defaultProps.onSuccess).toHaveBeenCalled();
      });
    });

    test('❌ แสดง error เมื่อ API ล้มเหลว', async () => {
      createBooking.mockRejectedValue(new Error('Network error'));
      renderBookingForm();

      await fillForm();
      await user.click(screen.getByRole('button', { name: /book now/i }));

      expect(await screen.findByText(/network error/i)).toBeInTheDocument();
      expect(defaultProps.onError).toHaveBeenCalled();
    });
  });
});
```

---

## ขั้นตอนที่ 3: เขียน API Integration Tests (MSW)

สร้างไฟล์ `frontend/src/__tests__/api.integration.test.js`:

```javascript
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Integration Tests: API Layer ด้วย Mock Service Worker (MSW)
// MSW intercepts fetch calls ใน tests แทน network จริง
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { describe, test, expect, beforeAll, afterAll, afterEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { bookingApi } from '../services/bookingApi';

// ─── Mock API Server ──────────────────────────────────────────
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

const server = setupServer(
  // GET /api/rooms
  http.get(`${API_URL}/api/rooms`, () => {
    return HttpResponse.json({
      success: true,
      data: [
        { id: 101, name: 'Deluxe Room', pricePerNight: 1500, available: true },
        { id: 102, name: 'Suite', pricePerNight: 3000, available: false },
      ],
    });
  }),

  // POST /api/bookings
  http.post(`${API_URL}/api/bookings`, async ({ request }) => {
    const body = await request.json();

    // Validate required fields
    if (!body.checkIn || !body.checkOut) {
      return HttpResponse.json(
        { success: false, error: 'Missing required fields' },
        { status: 400 }
      );
    }

    return HttpResponse.json({
      success: true,
      data: {
        id: 1,
        ...body,
        status: 'confirmed',
        totalPrice: 6000,
      },
    }, { status: 201 });
  }),

  // GET /api/bookings/:id
  http.get(`${API_URL}/api/bookings/:id`, ({ params }) => {
    const { id } = params;

    if (id === '999') {
      return HttpResponse.json(
        { success: false, error: 'Booking not found' },
        { status: 404 }
      );
    }

    return HttpResponse.json({
      success: true,
      data: {
        id: parseInt(id),
        roomId: 101,
        status: 'confirmed',
      },
    });
  }),
);

// ─── Setup / Teardown ─────────────────────────────────────────
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
describe('Booking API Integration Tests', () => {

  // ────────────────────────────────────────────────────────────
  describe('bookingApi.getRooms()', () => {

    test('✅ ดึงรายการห้องพักสำเร็จ', async () => {
      const rooms = await bookingApi.getRooms();

      expect(rooms).toHaveLength(2);
      expect(rooms[0]).toMatchObject({
        id: 101,
        name: 'Deluxe Room',
        pricePerNight: 1500,
      });
    });

    test('✅ กรองเฉพาะห้องที่ available', async () => {
      const rooms = await bookingApi.getRooms();
      const availableRooms = rooms.filter(r => r.available);

      expect(availableRooms).toHaveLength(1);
      expect(availableRooms[0].name).toBe('Deluxe Room');
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('bookingApi.createBooking()', () => {

    test('✅ สร้าง booking สำเร็จ', async () => {
      const result = await bookingApi.createBooking({
        roomId: 101,
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        guests: 2,
      });

      expect(result.success).toBe(true);
      expect(result.data.status).toBe('confirmed');
      expect(result.data.totalPrice).toBe(6000);
    });

    test('❌ โยน error เมื่อข้อมูลไม่ครบ', async () => {
      await expect(
        bookingApi.createBooking({ roomId: 101 })  // ขาด checkIn, checkOut
      ).rejects.toThrow();
    });

    test('❌ โยน error เมื่อ Network ล้มเหลว', async () => {
      // Override handler ให้ return network error
      server.use(
        http.post(`${API_URL}/api/bookings`, () => {
          return HttpResponse.error();
        })
      );

      await expect(bookingApi.createBooking({
        roomId: 101,
        checkIn: '2025-06-01',
        checkOut: '2025-06-05',
        guests: 2,
      })).rejects.toThrow();
    });
  });

  // ────────────────────────────────────────────────────────────
  describe('bookingApi.getBookingById()', () => {

    test('✅ ดึง booking ตาม ID สำเร็จ', async () => {
      const result = await bookingApi.getBookingById(1);

      expect(result.data.id).toBe(1);
      expect(result.data.status).toBe('confirmed');
    });

    test('❌ โยน error เมื่อไม่พบ booking', async () => {
      await expect(bookingApi.getBookingById(999))
        .rejects.toThrow(/not found/i);
    });
  });
});
```

---

## ขั้นตอนที่ 4: สร้าง GitHub Actions Workflow (Frontend)

สร้างไฟล์ `.github/workflows/frontend-ci-cd.yml`:

```yaml
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Frontend CI/CD Pipeline — React + Vite → Vercel
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
name: 🎨 Frontend CI/CD

# ─── Triggers ──────────────────────────────────────────────────
on:
  push:
    branches: [main, develop]
    paths:
      - 'frontend/**'
      - '.github/workflows/frontend-ci-cd.yml'
  pull_request:
    branches: [main]
    paths:
      - 'frontend/**'

# ─── Global Variables ──────────────────────────────────────────
env:
  NODE_VERSION: '18'
  WORKING_DIR: ./frontend

# ─── Prevent duplicate runs ────────────────────────────────────
concurrency:
  group: frontend-${{ github.ref }}
  cancel-in-progress: true

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jobs:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  # ────────────────────────────────────────────────────────────
  # JOB 1: Lint & Type Check
  # ────────────────────────────────────────────────────────────
  lint:
    name: 🔍 Lint & Type Check
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ⚙️ Setup Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

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
    name: 🧪 Unit Tests (Vitest)
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
          cache-dependency-path: frontend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🧪 Run Unit Tests with Coverage
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run test:coverage

      - name: 📊 Upload Coverage Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: frontend-coverage
          path: frontend/coverage/
          retention-days: 7

  # ────────────────────────────────────────────────────────────
  # JOB 3: Integration Tests
  # ────────────────────────────────────────────────────────────
  integration-tests:
    name: 🔗 Integration Tests (MSW)
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
          cache-dependency-path: frontend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🔗 Run Integration Tests
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run test:integration
        env:
          VITE_API_URL: http://localhost:3000  # MSW intercepts — ไม่ต้อง backend จริง

  # ────────────────────────────────────────────────────────────
  # JOB 4: Build Check
  # ────────────────────────────────────────────────────────────
  build:
    name: 🏗️ Production Build
    runs-on: ubuntu-latest
    needs: [unit-tests, integration-tests]

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: ⚙️ Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: 📦 Install dependencies
        working-directory: ${{ env.WORKING_DIR }}
        run: npm ci

      - name: 🏗️ Build for Production
        working-directory: ${{ env.WORKING_DIR }}
        run: npm run build
        env:
          VITE_API_URL: ${{ secrets.VITE_API_URL }}

      - name: 📦 Upload Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: frontend-build
          path: frontend/dist/
          retention-days: 3

  # ────────────────────────────────────────────────────────────
  # JOB 5: Deploy to Vercel (เฉพาะ main branch)
  # ────────────────────────────────────────────────────────────
  deploy:
    name: 🚀 Deploy to Vercel
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    environment:
      name: production
      url: ${{ steps.deploy.outputs.preview-url }}

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 📥 Download Build Artifact
        uses: actions/download-artifact@v4
        with:
          name: frontend-build
          path: frontend/dist

      - name: 🚀 Deploy to Vercel
        id: deploy
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend
          vercel-args: '--prod'

      - name: 🔍 Verify Deployment
        run: |
          echo "Deployed to: ${{ steps.deploy.outputs.preview-url }}"
          
          # Health check
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            "${{ steps.deploy.outputs.preview-url }}")
          
          if [ "$STATUS" = "200" ]; then
            echo "✅ Frontend deployment verified!"
          else
            echo "❌ Frontend health check failed (HTTP $STATUS)"
            exit 1
          fi

  # ────────────────────────────────────────────────────────────
  # JOB 6: Preview Deploy (สำหรับ PRs)
  # ────────────────────────────────────────────────────────────
  preview-deploy:
    name: 👀 Preview Deploy (PR)
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'pull_request'

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔍 Deploy Preview to Vercel
        id: preview
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend

      - name: 💬 Comment Preview URL on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 👀 Preview Deployment Ready!\n\n**URL:** ${{ steps.preview.outputs.preview-url }}\n\n**Commit:** \`${{ github.sha }}\`\n**Branch:** \`${{ github.head_ref }}\``
            })
```

---

## ขั้นตอนที่ 5: ทดสอบทั้งหมด

```bash
cd frontend

# รัน tests ทั้งหมด
npm run test

# รัน พร้อม coverage report
npm run test:coverage

# รัน integration tests
npm run test:integration

# ดู coverage report ใน browser
open coverage/index.html
```

### ผลลัพธ์ที่คาดหวัง

```
 ✓ src/__tests__/BookingForm.test.jsx (8 tests)
 ✓ src/__tests__/api.integration.test.js (6 tests)

 Test Files  2 passed (2)
 Tests       14 passed (14)

 Coverage:
   Lines:      82.4%
   Functions:  88.0%
   Branches:   75.2%
   Statements: 82.1%
```

---

## ✅ Checklist

- [ ] ติดตั้ง Vitest และ Testing Library แล้ว
- [ ] เขียน component tests อย่างน้อย 8 test cases
- [ ] เขียน API integration tests อย่างน้อย 5 test cases (ด้วย MSW)
- [ ] Coverage ≥ 75%
- [ ] สร้าง `frontend-ci-cd.yml` workflow แล้ว
- [ ] Push ขึ้น GitHub และ workflow รันสำเร็จ
- [ ] Deploy ไป Vercel สำเร็จ

---

[← LAB-02 Backend](LAB-02-BACKEND.md) | [ถัดไป: LAB-04 Security →](LAB-04-SECURITY.md)
