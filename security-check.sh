#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Security Check Script — Booking App Demo 2025
#
# ใช้: ./scripts/security-check.sh [API_URL]
# ตัวอย่าง:
#   ./scripts/security-check.sh http://localhost:3000
#   ./scripts/security-check.sh https://booking-backend.onrender.com
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

# ─── Configuration ────────────────────────────────────────────────────────
API_URL="${1:-http://localhost:3000}"
PASS=0
FAIL=0
WARN=0
REPORT_FILE="security-report.txt"

# ─── Colors ──────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ─── Helper Functions ──────────────────────────────────────────────────────
pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; PASS=$((PASS + 1)); echo "PASS: $1" >> "$REPORT_FILE"; }
fail() { echo -e "${RED}❌ FAIL${NC}: $1"; FAIL=$((FAIL + 1)); echo "FAIL: $1" >> "$REPORT_FILE"; }
warn() { echo -e "${YELLOW}⚠️  WARN${NC}: $1"; WARN=$((WARN + 1)); echo "WARN: $1" >> "$REPORT_FILE"; }
section() { echo -e "\n${BLUE}── $1 ${'─'*40}${NC}"; }

# ─── Initialize Report ────────────────────────────────────────────────────
echo "Security Check Report" > "$REPORT_FILE"
echo "URL: $API_URL" >> "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "=========================" >> "$REPORT_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Security Headers & Configuration Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Target: $API_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── ดึง Response Headers ─────────────────────────────────────────────────
HTTP_RESPONSE=$(curl -sI --max-time 15 "$API_URL/api/health" 2>/dev/null) || {
    echo -e "${RED}❌ Cannot connect to $API_URL${NC}"
    echo "Make sure the server is running and the URL is correct."
    exit 1
}

HTTP_STATUS=$(echo "$HTTP_RESPONSE" | head -1 | grep -oP '\d{3}')

# ════════════════════════════════════════════════════════════════
# 1. SECURITY HEADERS
# ════════════════════════════════════════════════════════════════
section "Security Headers"

# X-Content-Type-Options
if echo "$HTTP_RESPONSE" | grep -qi "x-content-type-options:.*nosniff"; then
    pass "X-Content-Type-Options: nosniff ✓"
else
    fail "X-Content-Type-Options: nosniff — MISSING (risk: MIME type confusion)"
fi

# X-Frame-Options
if echo "$HTTP_RESPONSE" | grep -qi "x-frame-options"; then
    FRAME_VALUE=$(echo "$HTTP_RESPONSE" | grep -i "x-frame-options" | cut -d: -f2 | tr -d ' \r')
    pass "X-Frame-Options: $FRAME_VALUE ✓"
else
    fail "X-Frame-Options — MISSING (risk: Clickjacking)"
fi

# Content-Security-Policy
if echo "$HTTP_RESPONSE" | grep -qi "content-security-policy"; then
    pass "Content-Security-Policy — PRESENT ✓"
else
    fail "Content-Security-Policy — MISSING (risk: XSS)"
fi

# Strict-Transport-Security
if echo "$HTTP_RESPONSE" | grep -qi "strict-transport-security"; then
    pass "Strict-Transport-Security (HSTS) — PRESENT ✓"
else
    warn "Strict-Transport-Security (HSTS) — MISSING (required for HTTPS)"
fi

# X-Powered-By (should NOT be present)
if ! echo "$HTTP_RESPONSE" | grep -qi "x-powered-by"; then
    pass "X-Powered-By — NOT EXPOSED ✓ (good!)"
else
    POWERED=$(echo "$HTTP_RESPONSE" | grep -i "x-powered-by" | cut -d: -f2 | tr -d ' \r')
    fail "X-Powered-By: $POWERED — EXPOSED (risk: version disclosure)"
fi

# Server header (should not expose version)
if echo "$HTTP_RESPONSE" | grep -qi "^server:"; then
    SERVER=$(echo "$HTTP_RESPONSE" | grep -i "^server:" | cut -d: -f2 | tr -d ' \r')
    if echo "$SERVER" | grep -qiE "nginx/[0-9]|apache/[0-9]"; then
        fail "Server version exposed: $SERVER (risk: targeted attacks)"
    else
        pass "Server header does not expose version ✓"
    fi
else
    pass "Server header — NOT PRESENT ✓ (good!)"
fi

# ════════════════════════════════════════════════════════════════
# 2. CORS CONFIGURATION
# ════════════════════════════════════════════════════════════════
section "CORS Configuration"

# ทดสอบ allowed origin
CORS_ALLOWED=$(curl -sI --max-time 10 \
    -H "Origin: http://localhost:5173" \
    "$API_URL/api/health" 2>/dev/null)

if echo "$CORS_ALLOWED" | grep -qi "access-control-allow-origin"; then
    CORS_ORIGIN=$(echo "$CORS_ALLOWED" | grep -i "access-control-allow-origin" | cut -d: -f2 | tr -d ' \r')
    pass "CORS: Allowed origin responds correctly ($CORS_ORIGIN)"
else
    warn "CORS: No Access-Control-Allow-Origin header for localhost:5173"
fi

# ทดสอบ wildcard CORS (ไม่ควรใช้ใน production)
if echo "$CORS_ALLOWED" | grep -qi "access-control-allow-origin: \*"; then
    fail "CORS: Wildcard (*) origin allowed — RISKY in production!"
else
    pass "CORS: Not using wildcard (*) origin ✓"
fi

# ทดสอบ malicious origin
CORS_BAD=$(curl -sI --max-time 10 \
    -H "Origin: https://malicious-site.com" \
    "$API_URL/api/health" 2>/dev/null)

CORS_BAD_ORIGIN=$(echo "$CORS_BAD" | grep -i "access-control-allow-origin" | cut -d: -f2 | tr -d ' \r')
if [ -z "$CORS_BAD_ORIGIN" ] || [ "$CORS_BAD_ORIGIN" != "https://malicious-site.com" ]; then
    pass "CORS: Malicious origin rejected ✓"
else
    fail "CORS: Malicious origin allowed! — CRITICAL"
fi

# ════════════════════════════════════════════════════════════════
# 3. AUTHENTICATION
# ════════════════════════════════════════════════════════════════
section "Authentication Security"

# ทดสอบ endpoint ที่ต้องการ authentication
AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$API_URL/api/bookings/1" 2>/dev/null)

if [ "$AUTH_STATUS" = "401" ]; then
    pass "Authentication required for protected endpoints (got 401) ✓"
elif [ "$AUTH_STATUS" = "403" ]; then
    pass "Authorization required for protected endpoints (got 403) ✓"
else
    warn "Protected endpoint returned HTTP $AUTH_STATUS (expected 401)"
fi

# ทดสอบ invalid JWT
INVALID_JWT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -H "Authorization: Bearer invalid.jwt.token.here" \
    "$API_URL/api/bookings/1" 2>/dev/null)

if [ "$INVALID_JWT_STATUS" = "401" ]; then
    pass "Invalid JWT token rejected (401) ✓"
else
    warn "Invalid JWT returned HTTP $INVALID_JWT_STATUS (expected 401)"
fi

# ════════════════════════════════════════════════════════════════
# 4. INPUT VALIDATION (Basic)
# ════════════════════════════════════════════════════════════════
section "Input Validation"

# SQL Injection ใน path parameter
SQLI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$API_URL/api/bookings/1%27%20OR%20%271%27%3D%271" 2>/dev/null)

if [ "$SQLI_STATUS" = "400" ] || [ "$SQLI_STATUS" = "401" ] || [ "$SQLI_STATUS" = "404" ]; then
    pass "SQL Injection in path handled safely (HTTP $SQLI_STATUS) ✓"
elif [ "$SQLI_STATUS" = "500" ]; then
    fail "SQL Injection caused server error (500)! — CRITICAL"
else
    warn "SQL Injection: unexpected HTTP $SQLI_STATUS"
fi

# XSS ใน query string
XSS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$API_URL/api/health?q=%3Cscript%3Ealert%281%29%3C%2Fscript%3E" 2>/dev/null)

if [ "$XSS_STATUS" != "500" ]; then
    pass "XSS in query string handled safely (HTTP $XSS_STATUS) ✓"
else
    fail "XSS in query string caused server error (500)!"
fi

# ════════════════════════════════════════════════════════════════
# 5. RATE LIMITING
# ════════════════════════════════════════════════════════════════
section "Rate Limiting"

echo "Testing rate limit on auth endpoint (sending 7 requests)..."
RATE_LIMITED=false
for i in $(seq 1 7); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
        -X POST "$API_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"brute@force.com","password":"wrong"}' 2>/dev/null)
    
    if [ "$STATUS" = "429" ]; then
        RATE_LIMITED=true
        break
    fi
done

if [ "$RATE_LIMITED" = "true" ]; then
    pass "Rate limiting active (got 429 Too Many Requests) ✓"
else
    warn "Rate limiting may not be configured (no 429 received in 7 requests)"
fi

# ════════════════════════════════════════════════════════════════
# 6. SUMMARY
# ════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Security Check Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ PASSED${NC}: $PASS checks"
echo -e "  ${RED}❌ FAILED${NC}: $FAIL checks"
echo -e "  ${YELLOW}⚠️  WARNED${NC}: $WARN checks"
TOTAL=$((PASS + FAIL + WARN))
echo "  📋 TOTAL : $TOTAL checks"
echo ""

if [ $TOTAL -gt 0 ]; then
    SCORE=$(echo "scale=0; $PASS * 100 / $TOTAL" | bc)
    echo "  🎯 Score : $SCORE%"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 Full report saved to: $REPORT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit code: 1 ถ้า fail count > 0
if [ $FAIL -gt 0 ]; then
    exit 1
fi

exit 0
