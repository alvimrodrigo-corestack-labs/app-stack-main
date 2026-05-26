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

# Install dependencies using workspace context
# We mount everything to ensure uv sync finds all members and pyprojects
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=.,target=. \
    uv sync --frozen --no-install-workspace --package app

# Copy source code
COPY ./backend/scripts /app/backend/scripts
COPY ./backend/pyproject.toml ./backend/alembic.ini /app/backend/
COPY ./backend/app /app/backend/app

# Final sync to ensure everything is ready
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=.,target=. \
    uv sync --frozen --package app

# FORÇAR instalação do boto3 no virtualenv para garantir acesso ao Secrets Manager
RUN /app/.venv/bin/python -m pip install boto3

WORKDIR /app/backend/

CMD ["fastapi", "run", "--workers", "4", "app/main.py"]
