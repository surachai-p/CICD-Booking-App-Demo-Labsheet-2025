# 🔒 LAB-04: Security Testing & NGINX Configuration

[← LAB-03 Frontend](LAB-03-FRONTEND.md) | [ถัดไป: LAB-ASSIGNMENT →](LAB-ASSIGNMENT.md)

---

## 🎯 เป้าหมาย

- ทดสอบ Security Headers ของ API
- ตั้งค่า NGINX เพื่อป้องกัน XSS และ CORS
- รัน Dependency Vulnerability Scan
- ทำความเข้าใจ OWASP Top 10

---

## ขั้นตอนที่ 1: NGINX Configuration สำหรับ Production

สร้างไฟล์ `nginx/nginx.conf`:

```nginx
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NGINX Configuration — Booking App Production
# ป้องกัน: XSS, Clickjacking, MIME Sniffing, CSRF
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── Worker Configuration ─────────────────────────────────────
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    # ─── Basic Settings ─────────────────────────────────────────
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    charset       utf-8;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;      # ❌ ซ่อน NGINX version ไม่ให้เห็น

    # ─── Logging ───────────────────────────────────────────────
    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log warn;

    # ─── Gzip Compression ──────────────────────────────────────
    gzip on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json 
               application/javascript text/xml 
               application/xml application/xml+rss text/javascript;

    # ─── Rate Limiting Zones ───────────────────────────────────
    # ป้องกัน Brute Force และ DDoS
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=3r/m;

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Server Block: Redirect HTTP → HTTPS
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    server {
        listen 80;
        server_name booking-app.example.com;
        
        # Force HTTPS redirect
        return 301 https://$host$request_uri;
    }

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Server Block: Frontend (React SPA)
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    server {
        listen 443 ssl http2;
        server_name booking-app.example.com;

        # ─── SSL Configuration ────────────────────────────────
        ssl_certificate     /etc/letsencrypt/live/booking-app.example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/booking-app.example.com/privkey.pem;
        ssl_protocols       TLSv1.2 TLSv1.3;
        ssl_ciphers         ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers on;
        ssl_session_cache   shared:SSL:10m;
        ssl_session_timeout 10m;

        root /var/www/booking-app/dist;
        index index.html;

        # ─── Security Headers ─────────────────────────────────
        # [1] ป้องกัน XSS (Cross-Site Scripting)
        add_header X-XSS-Protection "1; mode=block" always;

        # [2] ป้องกัน Content Type Sniffing
        add_header X-Content-Type-Options "nosniff" always;

        # [3] ป้องกัน Clickjacking (iframe embedding)
        add_header X-Frame-Options "SAMEORIGIN" always;

        # [4] Strict Transport Security (HSTS)
        # บังคับ HTTPS เป็นเวลา 1 ปี
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        # [5] Content Security Policy (CSP) — ป้องกัน XSS ขั้นสูง
        add_header Content-Security-Policy "
            default-src 'self';
            script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net;
            style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
            font-src 'self' https://fonts.gstatic.com;
            img-src 'self' data: https: blob:;
            connect-src 'self' https://your-backend.onrender.com;
            frame-src 'none';
            object-src 'none';
            base-uri 'self';
            form-action 'self';
        " always;

        # [6] Referrer Policy
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # [7] Permissions Policy (ป้องกันการใช้ browser features)
        add_header Permissions-Policy "
            camera=(),
            microphone=(),
            geolocation=(self),
            payment=()
        " always;

        # [8] ซ่อน server information
        more_clear_headers Server;

        # ─── CORS สำหรับ Static Files ─────────────────────────
        # (ส่วนใหญ่ CORS จะจัดการฝั่ง API แต่เพิ่มไว้เพื่อความสมบูรณ์)
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header X-Content-Type-Options "nosniff" always;
        }

        # ─── React Router (SPA) ───────────────────────────────
        location / {
            try_files $uri $uri/ /index.html;
            
            # ไม่ cache index.html เพื่อให้ได้ version ล่าสุด
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }

        # ─── ซ่อน sensitive files ─────────────────────────────
        location ~ /\. {
            deny all;
            return 404;
        }

        location ~* \.(env|config|bak|sql|log)$ {
            deny all;
            return 404;
        }
    }

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Server Block: Backend API Proxy
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    server {
        listen 443 ssl http2;
        server_name api.booking-app.example.com;

        # (SSL config เหมือนด้านบน)

        # ─── Security Headers ─────────────────────────────────
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # ─── CORS Headers ─────────────────────────────────────
        set $cors_origin "";
        
        if ($http_origin ~* "^https://booking-app.vercel.app$") {
            set $cors_origin $http_origin;
        }
        if ($http_origin ~* "^https://booking-app.example.com$") {
            set $cors_origin $http_origin;
        }

        # Preflight request
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin $cors_origin always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 86400;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }

        # ─── Rate Limiting ────────────────────────────────────
        # ป้องกัน Brute Force
        location /api/auth/login {
            limit_req zone=login burst=5 nodelay;
            limit_req_status 429;
            
            proxy_pass http://localhost:3000;
            include /etc/nginx/proxy_params;
        }

        # Rate limit ทั่วไป
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            limit_req_status 429;

            # ─── Proxy Settings ────────────────────────────────
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;

            # CORS Headers
            add_header Access-Control-Allow-Origin $cors_origin always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
            add_header Access-Control-Allow-Credentials "true" always;

            # ป้องกัน Response Splitting
            proxy_hide_header X-Powered-By;
        }

        # ─── Request Size Limit (ป้องกัน large payload attacks) ─
        client_max_body_size 10m;

        # ─── Block Common Attacks ─────────────────────────────
        # ป้องกัน path traversal
        if ($request_uri ~* "(\.\./|\.\.\\)") {
            return 400;
        }
    }
}
```

---

## ขั้นตอนที่ 2: Backend Security Middleware

อัปเดต `backend/src/app.js`:

```javascript
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Express App Security Configuration
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const xss = require('xss-clean');
const hpp = require('hpp');

const app = express();

// ─── 1. Helmet — Security Headers ─────────────────────────────
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", process.env.CORS_ORIGIN],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

// ─── 2. CORS — Cross-Origin Resource Sharing ─────────────────
const corsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = [
      process.env.CORS_ORIGIN,
      'http://localhost:5173',
      'http://localhost:3000',
    ].filter(Boolean);

    // อนุญาต request ที่ไม่มี origin (เช่น Postman)
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`CORS: Origin ${origin} not allowed`));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,  // Cache preflight 24 ชั่วโมง
};
app.use(cors(corsOptions));

// ─── 3. Rate Limiting ─────────────────────────────────────────
// ป้องกัน Brute Force และ DDoS
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 นาที
  max: 100,                    // สูงสุด 100 requests ต่อ window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too many requests. Please try again later.',
  },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,  // Login สูงสุด 5 ครั้งต่อ 15 นาที
  message: {
    success: false,
    error: 'Too many login attempts. Please try again in 15 minutes.',
  },
});

app.use('/api/', globalLimiter);
app.use('/api/auth/login', authLimiter);

// ─── 4. Body Parser ───────────────────────────────────────────
app.use(express.json({ limit: '10kb' }));  // จำกัดขนาด request body
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// ─── 5. XSS Protection ────────────────────────────────────────
// Sanitize user input ใน req.body, req.query, req.params
app.use(xss());

// ─── 6. HTTP Parameter Pollution Prevention ───────────────────
app.use(hpp());

// ─── 7. ซ่อน X-Powered-By ────────────────────────────────────
app.disable('x-powered-by');

// ... routes ถัดไป

module.exports = app;
```

---

## ขั้นตอนที่ 3: Security Check Script

สร้างไฟล์ `scripts/security-check.sh`:

```bash
#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Security Check Script
# ใช้ทดสอบ security headers ของ API ที่ deploy แล้ว
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

API_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Security Headers Check"
echo "URL: $API_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── ดึง Headers ──────────────────────────────────────────────
HEADERS=$(curl -sI "$API_URL/api/health")

# ─── Function: ตรวจสอบ header ────────────────────────────────
check_header() {
    local header="$1"
    local expected="$2"
    local description="$3"

    if echo "$HEADERS" | grep -qi "$header"; then
        echo "✅ PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $description"
        echo "   Expected header: $header"
        FAIL=$((FAIL + 1))
    fi
}

check_header_absent() {
    local header="$1"
    local description="$2"

    if ! echo "$HEADERS" | grep -qi "$header"; then
        echo "✅ PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $description"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "── Security Headers ────────────────────────────"
check_header "X-Content-Type-Options" "nosniff" "X-Content-Type-Options: nosniff"
check_header "X-Frame-Options" "" "X-Frame-Options present"
check_header "Content-Security-Policy" "" "Content-Security-Policy present"
check_header "Strict-Transport-Security" "" "HSTS header present"
check_header_absent "X-Powered-By" "X-Powered-By NOT exposed"
check_header_absent "Server: nginx" "NGINX version NOT exposed"

echo ""
echo "── CORS Headers ─────────────────────────────────"
CORS_HEADERS=$(curl -sI -H "Origin: http://localhost:5173" "$API_URL/api/health")

if echo "$CORS_HEADERS" | grep -qi "Access-Control-Allow-Origin"; then
    echo "✅ PASS: CORS header present for allowed origin"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: CORS header missing"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "── Rate Limiting ────────────────────────────────"
echo "Testing rate limiting (sending 6 requests to auth endpoint)..."
RATE_LIMITED=false
for i in $(seq 1 6); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$API_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"test@test.com","password":"wrong"}')
    if [ "$STATUS" = "429" ]; then
        RATE_LIMITED=true
        break
    fi
done

if [ "$RATE_LIMITED" = "true" ]; then
    echo "✅ PASS: Rate limiting is working (got 429)"
    PASS=$((PASS + 1))
else
    echo "⚠️  WARN: Rate limiting may not be configured (no 429 received)"
fi

echo ""
echo "── XSS Basic Test ───────────────────────────────"
XSS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    "$API_URL/api/health?q=<script>alert(1)</script>")
if [ "$XSS_RESPONSE" != "500" ]; then
    echo "✅ PASS: XSS in query string handled gracefully (HTTP $XSS_RESPONSE)"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: XSS in query string caused 500 error"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "── SQL Injection Basic Test ─────────────────────"
SQLI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "$API_URL/api/bookings/1%27%20OR%20%271%27=%271")
if [ "$SQLI_STATUS" = "400" ] || [ "$SQLI_STATUS" = "404" ]; then
    echo "✅ PASS: SQL injection in URL handled (HTTP $SQLI_STATUS)"
    PASS=$((PASS + 1))
else
    echo "⚠️  WARN: Unexpected response to SQL injection: HTTP $SQLI_STATUS"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results: ✅ $PASS passed | ❌ $FAIL failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
```

```bash
chmod +x scripts/security-check.sh

# รันทดสอบกับ local
./scripts/security-check.sh http://localhost:3000

# รันทดสอบกับ production
./scripts/security-check.sh https://your-backend.onrender.com
```

---

## ขั้นตอนที่ 4: OWASP Top 10 Checklist

ทดสอบและบันทึกผลในตารางนี้:

| # | OWASP Category | การทดสอบ | ผลลัพธ์ |
|---|---------------|---------|---------|
| A01 | Broken Access Control | ลอง GET /api/bookings/1 โดยไม่มี token → ต้องได้ 401 | ⬜ |
| A02 | Cryptographic Failures | ตรวจสอบ HTTPS และ JWT secret length ≥ 32 chars | ⬜ |
| A03 | Injection | ส่ง `' OR '1'='1` ใน booking ID → ต้องได้ 400 | ⬜ |
| A05 | Security Misconfiguration | X-Powered-By ต้องไม่มี | ⬜ |
| A06 | Vulnerable Components | `npm audit` ต้องไม่มี high/critical | ⬜ |
| A07 | Auth Failures | ส่ง token หมดอายุ → ต้องได้ 401 | ⬜ |
| A09 | Logging & Monitoring | ตรวจสอบว่ามี access log บน server | ⬜ |

---

## ขั้นตอนที่ 5: Dependency Vulnerability Scan

```bash
# ─── Backend ───────────────────────────────────────────────────
cd backend
npm audit                          # แสดงทุก vulnerability
npm audit --audit-level=high       # Fail เฉพาะ high/critical
npm audit fix                      # แก้อัตโนมัติ (ถ้าทำได้)

# ─── Frontend ──────────────────────────────────────────────────
cd frontend
npm audit
npm audit --audit-level=high
```

ผลลัพธ์ที่คาดหวัง:

```
found 0 vulnerabilities   ← ดีที่สุด
```

หรืออย่างน้อย:

```
found X vulnerabilities (Y moderate, 0 high, 0 critical)
```

---

## ขั้นตอนที่ 6: เพิ่ม Security Job ใน Workflow

เพิ่มใน `.github/workflows/backend-ci-cd.yml`:

```yaml
  # ─── Security Scan Job (เพิ่มเติม) ───────────────────────────
  production-security-scan:
    name: 🔒 Production Security Scan
    runs-on: ubuntu-latest
    needs: deploy
    if: github.ref == 'refs/heads/main'

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔒 Run Security Check Script
        run: |
          chmod +x scripts/security-check.sh
          ./scripts/security-check.sh ${{ secrets.RENDER_BACKEND_URL }}

      - name: 📊 Upload Security Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: security-report
          path: security-report.txt
          retention-days: 30
```

---

## ✅ Checklist

- [ ] สร้าง `nginx/nginx.conf` พร้อม security headers ครบถ้วน
- [ ] เพิ่ม Helmet.js middleware ใน Express
- [ ] ตั้งค่า CORS ให้ถูกต้อง (อนุญาตเฉพาะ frontend URL)
- [ ] ตั้งค่า Rate Limiting
- [ ] รัน `scripts/security-check.sh` และ pass ≥ 80%
- [ ] รัน `npm audit` ไม่พบ high/critical vulnerabilities
- [ ] กรอก OWASP Top 10 Checklist ครบ

---

## 📖 อ่านเพิ่มเติม

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Helmet.js Documentation](https://helmetjs.github.io/)
- [NGINX Security Headers](https://nginx.org/en/docs/http/ngx_http_headers_module.html)
- [Content Security Policy Guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

---

[← LAB-03 Frontend](LAB-03-FRONTEND.md) | [ถัดไป: LAB-ASSIGNMENT →](LAB-ASSIGNMENT.md)
