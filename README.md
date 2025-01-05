# Tharsus Django Project Template

> Django project template with batteries included, forked from [jefftriplett/django-startproject](https://github.com/jefftriplett/django-startproject)

## Features

- Django 5.1 + Python 3.13
- PostgreSQL + Docker Compose
- django-ninja API with token authentication
- Custom User model with email authentication
- Comprehensive test setup with pytest
- Modern development tools:
  - uv for dependency management
  - ruff for linting/formatting
  - pre-commit hooks
  - justfile for common tasks

## Quick Start

```shell
# Create new project
uv run --with=django django-admin startproject \
    --extension=ini,py,toml,yaml,yml \
    --template=https://github.com/tharsus-mons/django-startproject/archive/main.zip \
    project_name

cd project_name

# Setup project
just bootstrap  # Creates venv, installs deps, sets up db
just runserver  # Starts development server
```

## Development Commands

```shell
just bootstrap              # Setup project (venv, deps, db)
just runserver             # Run Django development server
just test                  # Run pytest
just lint                  # Run pre-commit hooks
just manage [cmd]          # Run Django management commands

# Database
just db-up                 # Start database container
just db-down              # Stop database container
just restart-db           # Restart database
just pg_dump              # Dump database to file
just pg_restore           # Restore database from dump

# Deployment
just fly-launch           # Initialize Fly.io app
just fly-deploy          # Deploy to Fly.io
```

## Optional Features

### Clerk Authentication

1. Enable in `pyproject.toml`:
   ```toml
   clerk-backend-api = ">=0.1"
   ```

2. Configure in `.env`:
   ```
   USE_CLERK=True
   CLERK_SECRET_KEY=your-clerk-secret-key
   CLERK_JWT_KEY=your-clerk-jwt-key
   FRONTEND_URL=http://localhost:3000
   ```

## API Endpoints

- `GET /api/users/me/` - Get current user
- `PATCH /api/users/me/` - Update user
- `DELETE /api/users/me/` - Delete account
