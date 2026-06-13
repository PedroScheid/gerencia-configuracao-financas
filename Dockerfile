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

# Healthcheck na raiz (publica, serve o index.html) -> 200 OK.
# Antes apontava para /api/auth/me, que exige login e retornava 401,
# marcando o container como (unhealthy) mesmo com a app no ar.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/ || exit 1

CMD ["node", "backend/dist/index.js"]
