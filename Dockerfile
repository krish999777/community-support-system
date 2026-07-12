# ---------- FRONTEND BUILD ----------
FROM node:20 AS frontend-build
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm install

COPY frontend/ .
RUN npm run build


# ---------- BACKEND ----------
FROM node:20
WORKDIR /app

# Install backend deps
COPY backend/package*.json ./backend/
RUN cd backend && npm install

# Copy backend source
COPY backend/ ./backend/

# Copy React build into backend public folder
COPY --from=frontend-build /app/frontend/dist ./backend/public

EXPOSE 3000

CMD ["node", "backend/doner_receipt_app/server.js"]