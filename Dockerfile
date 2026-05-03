FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN mkdir -p /install && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt


FROM python:3.12-slim AS runtime

WORKDIR /app

COPY --from=builder /install /usr/local
COPY app.py .

RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

USER appuser

EXPOSE 3001

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3001/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:3001", "--workers", "2", "--timeout", "30", "--access-logfile", "-", "app:app"]