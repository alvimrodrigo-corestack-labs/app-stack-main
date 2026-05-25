# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
