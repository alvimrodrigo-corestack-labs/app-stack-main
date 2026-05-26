FROM python:3.10

ENV PYTHONUNBUFFERED=1

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

# Compile bytecode
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

WORKDIR /app/

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Copy workspace configuration files first for better caching
COPY pyproject.toml uv.lock ./
COPY backend/pyproject.toml ./backend/

# Install dependencies (frozen) - Isso garante que o grosso venha do lock
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-workspace --package app

# Copy application source code
COPY ./backend /app/backend

# Final sync SEM --frozen para permitir que o boto3 (adicionado ao pyproject.toml) seja instalado
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --package app

# Garantia final: instalar boto3 explicitamente caso o uv sync o ignore por causa do lock
RUN uv pip install boto3

WORKDIR /app/backend/

CMD ["fastapi", "run", "--workers", "4", "app/main.py"]
