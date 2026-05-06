# ── Production Stage (pre-built by Jenkins) ─────────────────
FROM node:20-alpine

WORKDIR /app

# Install production dependencies first (cacheable layer)
COPY backend/package*.json ./backend/
RUN cd backend && npm ci --omit=dev

# Copy pre-built backend (compiled by Jenkins)
COPY backend/dist ./backend/dist
COPY backend/src/database/migrations ./backend/dist/database/migrations

# Copy pre-built frontend (compiled by Jenkins)
COPY frontend/dist ./frontend/dist

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
