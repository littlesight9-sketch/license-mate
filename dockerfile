# ==========================================
# Stage 1: Build Frontend
# ==========================================
FROM node:20-alpine AS frontend

WORKDIR /app/server-ui

COPY server-ui/package*.json ./

RUN npm ci

COPY server-ui/ ./

RUN npm run build


# ==========================================
# Stage 2: Install Backend Dependencies
# ==========================================
FROM python:3.11-slim AS backend

RUN pip install --no-cache-dir poetry==1.6.1

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    PYTHONUNBUFFERED=1

WORKDIR /app/server

COPY server/pyproject.toml server/poetry.lock ./

RUN poetry install --with prod --no-root


# ==========================================
# Stage 3: Production Image
# ==========================================
FROM python:3.11-slim

WORKDIR /app/server

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=10000

# Copy Python dependencies
COPY --from=backend /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

COPY --from=backend /usr/local/bin /usr/local/bin

# Explicitly install Gunicorn
RUN pip install --no-cache-dir gunicorn==21.2.0

# Copy backend
COPY server/ ./

# Copy compiled frontend
COPY --from=frontend /app/server/static/js/server-ui.js ./static/js/server-ui.js

EXPOSE 10000

CMD ["sh", "-c", "gunicorn main:app --bind 0.0.0.0:${PORT:-10000} --workers 2 --timeout 120"]
