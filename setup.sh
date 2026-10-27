#!/usr/bin/env bash

# Color codes for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    METANODE FINSDK PROJECT SETUP (macOS/Linux) ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Helper function to print messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Check Node.js
log_info "Checking Node.js version..."
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed! Please install Node.js (version >= 18) and try again."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2)
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d'.' -f1)

if [ "$NODE_MAJOR" -lt 18 ]; then
    log_error "Your Node.js version is v$NODE_VERSION. Version >= 18 is required."
    exit 1
else
    log_success "Node.js v$NODE_VERSION detected."
fi

# 2. Check pnpm
log_info "Checking pnpm..."
if ! command -v pnpm &> /dev/null; then
    log_warn "pnpm is not installed. Attempting to install pnpm via corepack..."
    if command -v corepack &> /dev/null; then
        corepack enable
        corepack prepare pnpm@9.0.0 --activate
    else
        log_warn "Corepack is not available. Attempting npm global install..."
        npm install -g pnpm@9.0.0
    fi
fi

if ! command -v pnpm &> /dev/null; then
    log_error "Could not install pnpm automatically. Please install pnpm manually (npm install -g pnpm) and rerun."
    exit 1
fi

PNPM_VERSION=$(pnpm -v)
log_success "pnpm v$PNPM_VERSION detected."

# 3. Setup Env Files
log_info "Configuring environment files..."
if [ -f .env.example ]; then
    if [ ! -f .env.development ]; then
        cp .env.example .env.development
        log_success "Created .env.development from template."
    else
        log_info ".env.development already exists, skipping."
    fi

    if [ ! -f .env.production ]; then
        cp .env.example .env.production
        log_success "Created .env.production from template."
    else
        log_info ".env.production already exists, skipping."
    fi
else
    log_warn ".env.example not found. Cannot auto-generate environment files."
fi

# 4. Remove npm/yarn leftovers (mixed managers create .ignored / EPERM on Windows)
log_info "Checking for foreign lockfiles (npm/yarn)..."
find . -name 'package-lock.json' -not -path './.git/*' -print -delete 2>/dev/null || true
find . -name 'yarn.lock' -not -path './.git/*' -print -delete 2>/dev/null || true
find . -name 'npm-shrinkwrap.json' -not -path './.git/*' -print -delete 2>/dev/null || true

# 5. Install dependencies (pnpm only — never npm/yarn)
log_info "Installing dependencies..."
pnpm install
if [ $? -ne 0 ]; then
    log_error "Dependency installation failed. Please check logs above."
    exit 1
fi
log_success "Dependencies installed successfully."

# 6. Build workspace packages dependencies
log_info "Building workspace packages..."
pnpm --filter @metanodejs/bls-crypto --filter @metanodejs/meta-proto --filter @metanodejs/fiai-sdk build
if [ $? -ne 0 ]; then
    log_error "Failed to build workspace packages."
    exit 1
fi
log_success "Workspace packages built successfully."

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}    SETUP COMPLETED SUCCESSFULLY!              ${NC}"
echo -e "${GREEN}===============================================${NC}\n"

echo -e "You can now start the development server using:"
echo -e "  ${YELLOW}pnpm dev${NC}\n"

read -p "Do you want to start the development server now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Starting development server..."
    pnpm dev
fi
