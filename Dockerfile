# syntax=docker/dockerfile:1.9
FROM python:3.13-slim-bookworm AS build

SHELL ["sh", "-exc"]

# Install build dependencies
RUN apt-get update -qy && apt-get install -qy \
    -o APT::Install-Recommends=false \
    -o APT::Install-Suggests=false \
    build-essential \
    python3-dev \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy and install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=/usr/local/bin/python3 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/src

# Create virtual environment
RUN python -m venv /app

# Copy project configuration and install dependencies
COPY pyproject.toml /tmp/
RUN --mount=type=cache,target=/root/.cache \
    cd /tmp && \
    uv pip sync \
        --python=/app/bin/python \
        pyproject.toml

# Copy application files
COPY . /src/

##########################################################################

FROM python:3.13-slim-bookworm

SHELL ["sh", "-exc"]

# Create non-root user
RUN groupadd -r app && \
    useradd -r -d /app -g app -N app

# Install runtime dependencies
RUN apt-get update -qy && apt-get install -qy \
    -o APT::Install-Recommends=false \
    -o APT::Install-Suggests=false \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build --chown=app:app /app /app
COPY --from=build --chown=app:app /src /src
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /src/
USER app
ENV PATH=/app/bin:$PATH \
    PYTHONPATH=/src

EXPOSE 8000

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
