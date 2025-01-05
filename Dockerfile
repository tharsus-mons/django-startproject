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
    UV_PYTHON=python3 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/srv

# Create virtual environment and install dependencies
RUN python -m venv /app
COPY requirements.txt /tmp/
RUN --mount=type=cache,target=/root/.cache \
    . /app/bin/activate && \
    /usr/local/bin/uv pip install --requirement /tmp/requirements.txt

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
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --chown=app:app . /src/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /src/
USER app
ENV PATH=/app/bin:$PATH

EXPOSE 8000

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
