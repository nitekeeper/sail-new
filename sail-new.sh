#!/usr/bin/env bash

# ============================================================
# sail-new — Laravel Sail Bootstrapper
# Clean Global Wrapper Architecture
# ============================================================

set -e

# ------------------------------------------------------------
# Detect if script is sourced
# ------------------------------------------------------------
(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0

# ------------------------------------------------------------
# Base directory (absolute path safe)
# ------------------------------------------------------------
BASE_DIR="$(pwd)"

# ------------------------------------------------------------
# Portable script path
# ------------------------------------------------------------
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)/$(basename "$SCRIPT_SOURCE")"

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${CYAN}➜${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✖${NC} $1"; }

# ------------------------------------------------------------
# One-time alias bootstrap (for sail-new command)
# ------------------------------------------------------------
ALIAS_LINE="alias sail-new='source $SCRIPT_PATH'"

if ! grep -Fxq "$ALIAS_LINE" "$HOME/.bashrc" 2>/dev/null; then
    echo ""
    info "Installing sail-new command..."
    echo "$ALIAS_LINE" >> "$HOME/.bashrc"

    success "Alias installed in ~/.bashrc"
    echo "Run: source ~/.bashrc"
    return 0 2>/dev/null || exit 0
fi

# ------------------------------------------------------------
# Install global Sail wrapper (ONE TIME ONLY)
# ------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
SailWrapper="$HOME/.local/bin/sail"

if [[ ! -f "$SailWrapper" ]]; then
    info "Installing global sail wrapper..."

    cat > "$SailWrapper" <<'EOF'
#!/usr/bin/env bash

# Automatically use project-local Sail if available
if [[ -f "./vendor/bin/sail" ]]; then
    ./vendor/bin/sail "$@"
else
    echo "Sail not found in this directory."
    echo "Run this inside a Laravel project."
    exit 1
fi
EOF

    chmod +x "$SailWrapper"

    success "Global sail wrapper installed in ~/.local/bin"

    # Ensure PATH contains ~/.local/bin
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        warn "Added ~/.local/bin to PATH in ~/.bashrc"
        echo "Run: source ~/.bashrc"
    fi
fi

# ------------------------------------------------------------
# Abort handling
# ------------------------------------------------------------
abort() {
    echo ""
    warn "Aborted."
    return 1 2>/dev/null || exit 1
}
trap abort INT

# ------------------------------------------------------------
# Docker check
# ------------------------------------------------------------
if ! docker info >/dev/null 2>&1; then
    error "Docker is not running."
    abort
fi

# ------------------------------------------------------------
# Project name input
# ------------------------------------------------------------
while true; do
    echo ""
    read -rp "Project name (or 'q' to quit): " PROJECT

    [[ "$PROJECT" =~ ^(q|quit|abort)$ ]] && abort
    [[ -z "$PROJECT" ]] && { warn "Project name cannot be empty."; continue; }

    PROJECT_PATH="$BASE_DIR/$PROJECT"

    [[ -d "$PROJECT_PATH" ]] && { warn "Directory already exists."; continue; }

    break
done

# ------------------------------------------------------------
# Supported Sail services
# ------------------------------------------------------------
ALLOWED_SERVICES=(
    mysql
    pgsql
    mariadb
    redis
    memcached
    meilisearch
    typesense
    minio
    mailpit
    selenium
    mongodb
)

while true; do
    echo ""
    echo "Supported services:"
    echo "${ALLOWED_SERVICES[*]}"
    echo ""

    read -rp "Enter services (comma-separated) [default: mysql]: " SERVICES
    [[ -z "$SERVICES" ]] && SERVICES="mysql"

    SERVICES="${SERVICES// /}"
    SERVICES="$(echo "$SERVICES" | tr '[:upper:]' '[:lower:]')"

    IFS=',' read -ra INPUT <<< "$SERVICES"

    VALID=()
    INVALID=()

    for svc in "${INPUT[@]}"; do
        if [[ " ${ALLOWED_SERVICES[*]} " == *" $svc "* ]]; then
            VALID+=("$svc")
        else
            INVALID+=("$svc")
        fi
    done

    if [[ ${#INVALID[@]} -gt 0 ]]; then
        warn "Invalid service(s): ${INVALID[*]}"
        continue
    fi

    SERVICES=$(IFS=,; echo "${VALID[*]}")
    break
done

# ------------------------------------------------------------
# Optional DB Port
# ------------------------------------------------------------
echo ""
read -rp "Custom DB port? (leave empty for default): " DB_PORT

# ------------------------------------------------------------
# Create Laravel project (UID/GID safe)
# ------------------------------------------------------------
info "Creating Laravel project..."

docker run --rm \
    --pull=always \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    -v "$BASE_DIR":/opt \
    -w /opt \
    laravelsail/php84-composer:latest \
    bash -c "
        groupadd -g \$HOST_GID sailgroup 2>/dev/null || true
        useradd -m -u \$HOST_UID -g \$HOST_GID sailuser 2>/dev/null || true
        su sailuser -c 'laravel new $PROJECT --no-interaction'
    "

# ------------------------------------------------------------
# Verify directory
# ------------------------------------------------------------
if [[ ! -d "$PROJECT_PATH" ]]; then
    error "Project directory not created."
    exit 1
fi

cd "$PROJECT_PATH"

# ------------------------------------------------------------
# Install Sail
# ------------------------------------------------------------
php artisan sail:install --with="$SERVICES" --no-interaction

# ------------------------------------------------------------
# Apply custom DB port
# ------------------------------------------------------------
if [[ -n "$DB_PORT" ]]; then
    if grep -q "^DB_PORT=" .env; then
        sed -i.bak "s/^DB_PORT=.*/DB_PORT=$DB_PORT/" .env
    else
        echo "DB_PORT=$DB_PORT" >> .env
    fi
fi

# ------------------------------------------------------------
# Build containers
# ------------------------------------------------------------
./vendor/bin/sail build

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------
echo ""
success "Project '$PROJECT' is ready 🚀"

if [ "$SOURCED" -eq 1 ]; then
    cd "$PROJECT_PATH"
    success "Entered project directory."
fi

echo ""
echo "Next step:"
echo "  sail up -d"
echo ""
