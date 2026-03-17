FROM python:3.13.12-slim

# Pin uv version for reproducible builds
COPY --from=ghcr.io/astral-sh/uv:0.10.9 /uv /uvx /bin/

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_NO_DEV=1
ENV HOME=/home/appuser
ENV UV_CACHE_DIR=/home/appuser/.cache/uv

WORKDIR /app

# Create non-root user
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/appuser" \
    --shell "/usr/sbin/nologin" \
    --uid "${UID}" \
    appuser

# Copy lock + project metadata first for layer caching
COPY pyproject.toml uv.lock ./

# Install dependencies from lockfile
RUN uv sync --locked --no-dev

# Copy source
COPY . .

# Ensure runtime user can write logs/cache and access project files.
RUN chown -R appuser:appuser /app /home/appuser

USER appuser

# Discord bot process 
CMD ["uv", "run", "app/main.py"]