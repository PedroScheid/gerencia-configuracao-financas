# ── Build Stage ──────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Backend dependencies
COPY backend/package*.json backend/
RUN cd backend && npm ci

# Frontend dependencies
COPY frontend/package*.json frontend/
RUN cd frontend && npm ci

# Copy source
COPY backend/ backend/
COPY frontend/ frontend/

# Build backend (TypeScript → JS)
RUN cd backend && npm run build

# Build frontend (React → static)
RUN cd frontend && npm run build

# ── Production Stage ─────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

# Copy built backend
COPY --from=builder /app/backend/dist ./backend/dist
COPY --from=builder /app/backend/package*.json ./backend/
COPY --from=builder /app/backend/src/database/migrations ./backend/dist/database/migrations

# Copy built frontend
COPY --from=builder /app/frontend/dist ./frontend/dist

# Install production dependencies only
RUN cd backend && npm ci --omit=dev

# Create data directory for SQLite
RUN mkdir -p /data

ENV NODE_ENV=production
ENV PORT=3000
ENV DB_PATH=/data/financas.db
ENV STATIC_PATH=/app/frontend/dist

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/auth/me || exit 1

CMD ["node", "backend/dist/index.js"]
