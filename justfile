set dotenv-load := false

@_default:
    just --list

@_cog:
    uv run --with cogapp cog -r README.md

@_fmt:
    just --fmt --unstable

bootstrap *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ ! -f ".env" ]; then
        cp .env-dist .env
        echo ".env created"
    fi

    if [ ! -f "fly.toml" ] && [ -f "fly.toml-tpl" ]; then
        cp fly.toml-tpl fly.toml
        rm fly.toml-tpl
        echo "fly.toml created"
    fi

    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
        echo "Creating virtual environment..."
        uv venv
    fi

    # Activate virtual environment
    source .venv/bin/activate

    uv pip sync pyproject.toml

    just db-up
    echo "Waiting for database to be ready..."
    sleep 3

    echo "Running migrations..."
    uv run python -m manage migrate

    if [ -z "${DJANGO_SUPERUSER_USERNAME-}" ] || [ -z "${DJANGO_SUPERUSER_PASSWORD-}" ] || [ -z "${DJANGO_SUPERUSER_EMAIL-}" ]; then
        echo "Creating superuser interactively..."
        uv run python -m manage createsuperuser
    else
        echo "Creating superuser from environment variables..."
        uv run python -m manage createsuperuser --noinput
    fi

@db-up *ARGS:
    docker compose up -d db {{ ARGS }}

@db-down *ARGS:
    docker compose stop db {{ ARGS }}
    docker compose rm -f db {{ ARGS }}

@lint *ARGS:
    uv run --with pre-commit-uv pre-commit run {{ ARGS }} --all-files

@lock *ARGS:
    uv pip compile {{ ARGS }} pyproject.toml

@logs *ARGS:
    docker compose logs db {{ ARGS }}

@manage *ARGS:
    uv run python -m manage {{ ARGS }}

# dump database to file
@pg_dump file='db.dump':
    docker compose exec \
        db pg_dump \
            --dbname "${DATABASE_URL:=postgres://postgres@localhost/postgres}" \
            --file /src/{{ file }} \
            --format=c \
            --verbose

# restore database dump from file
@pg_restore file='db.dump':
    docker compose exec \
        db pg_restore \
            --clean \
            --dbname "${DATABASE_URL:=postgres://postgres@localhost/postgres}" \
            --if-exists \
            --no-owner \
            --verbose \
            /src/{{ file }}

@restart-db:
    just db-down
    just db-up

@runserver *ARGS:
    uv run python -m manage runserver {{ ARGS }}

@test *ARGS:
    uv run python -m pytest {{ ARGS }}

@upgrade:
    just lock --upgrade

@fly-launch *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail

    flyctl launch \
        --no-deploy \
        --copy-config \
        --dockerfile Dockerfile \
        {{ ARGS }}

    echo "\nIMPORTANT: Set required secrets to avoid 400 errors:"
    echo "Run: flyctl secrets set ALLOWED_HOSTS=your-app.fly.dev"
    echo "Add any other required secrets like DATABASE_URL, SECRET_KEY, etc."
    echo "Example: flyctl secrets set SECRET_KEY=your-secret-key"

@fly-deploy *ARGS:
    flyctl deploy {{ ARGS }}
