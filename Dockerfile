# ------------------------------------------------------------
# Base/builder layer
# ------------------------------------------------------------

FROM python:3.13-slim-bookworm AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONPATH /srv
ENV PYTHONUNBUFFERED 1

COPY requirements.txt /tmp/requirements.txt

# add ",sharing=locked" if release should block until builder is complete
RUN --mount=type=cache,target=/root/.cache,sharing=locked,id=pip \
    python -m pip install --upgrade pip uv just-bin

RUN --mount=type=cache,target=/root/.cache,sharing=locked,id=pip \
    python -m uv pip install --system --requirement /tmp/requirements.txt

# Install system dependencies
RUN apt-get update && apt-get install -y \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM builder AS release

COPY . /src/
WORKDIR /src/

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8000

# Use supervisord as the entry point
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
