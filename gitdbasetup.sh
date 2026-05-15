#!/bin/bash
# =============================================================================
# git_dba_setup.sh — Git Setup & DBA Repo Initialisation (Ubuntu)
# Run once to configure Git and scaffold your DBA script repository.
# =============================================================================

set -e

# ── CONFIG — edit before running ─────────────────────────────────────────────
GIT_NAME="Your Name"
GIT_EMAIL="you@company.com"
REPO_DIR="$HOME/dba-scripts"          # local repo location
REMOTE_URL=""                          # optional: git@github.com:you/dba-scripts.git
# ─────────────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
info()    { echo -e "${GREEN}[+]${RESET} $*"; }
section() { echo -e "\n${CYAN}── $* ──${RESET}"; }

# =============================================================================
# 1. INSTALL GIT
# =============================================================================
section "Installing Git"
sudo apt-get update -qq
sudo apt-get install -y git git-extras
git --version
info "Git installed"

# =============================================================================
# 2. GLOBAL CONFIGURATION
# =============================================================================
section "Global Git Config"
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.editor        "nano"          # change to vim/code if preferred
git config --global init.defaultBranch "main"
git config --global core.autocrlf      "input"         # Linux: keep LF
git config --global pull.rebase        false
git config --global push.default       simple
git config --global core.fileMode      true
git config --global alias.st          "status -sb"
git config --global alias.lg          "log --oneline --graph --decorate --all"
git config --global alias.last        "log -1 HEAD --stat"
git config --global alias.undo        "reset HEAD~1 --mixed"
git config --global alias.staged      "diff --cached"
info "Global config set"
git config --global --list

# =============================================================================
# 3. SSH KEY GENERATION (for GitHub/GitLab/Bitbucket)
# =============================================================================
section "SSH Key"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
    info "SSH key created: $SSH_KEY"
else
    info "SSH key already exists: $SSH_KEY"
fi

echo ""
echo -e "${YELLOW}▶ Copy this public key to GitHub/GitLab → Settings → SSH Keys:${RESET}"
cat "${SSH_KEY}.pub"
echo ""

# =============================================================================
# 4. INITIALISE DBA REPO WITH STANDARD STRUCTURE
# =============================================================================
section "Scaffolding DBA Repository at $REPO_DIR"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init

# Folder structure
mkdir -p \
    maintenance \
    backups \
    queries/adhoc \
    queries/reports \
    monitoring \
    etl \
    security \
    docs

# .gitignore — keep secrets and logs out
cat > .gitignore << 'EOF'
# Credentials & secrets
*.env
*.secret
.env*
secrets/
passwords.txt

# Logs & temp
*.log
*.tmp
*.bak
/logs/

# OS
.DS_Store
Thumbs.db

# SQL Server backup files (large binaries)
*.bak
*.mdf
*.ldf
*.ndf

# Editor
.vscode/
*.swp
*~
EOF

# README
cat > README.md << 'EOF'
# DBA Scripts Repository

Centralised store for all database administration scripts, queries, and maintenance utilities.

## Structure

| Folder              | Purpose                                      |
|---------------------|----------------------------------------------|
| `maintenance/`      | Daily/weekly maintenance scripts             |
| `backups/`          | Backup & restore scripts                     |
| `queries/adhoc/`    | One-off investigative queries                |
| `queries/reports/`  | Recurring report queries (SSRS-ready)        |
| `monitoring/`       | Health checks & alerting scripts             |
| `etl/`              | SSIS / ETL pipeline scripts                  |
| `security/`         | Audit, permissions, vulnerability scripts    |
| `docs/`             | Runbooks, architecture notes                 |

## Conventions

- Script names: `lowercase_with_underscores.sh` / `.sql`
- Every script must have a header comment: purpose, author, date, version
- Never commit credentials — use environment variables or a secrets manager
- Tag releases: `git tag -a v1.0 -m "Initial stable release"`
EOF

git add .
git commit -m "chore: initial DBA repo scaffold"
info "Repository initialised with first commit"

# =============================================================================
# 5. ADD REMOTE (optional)
# =============================================================================
if [[ -n "$REMOTE_URL" ]]; then
    section "Adding Remote"
    git remote add origin "$REMOTE_URL"
    git push -u origin main
    info "Pushed to remote: $REMOTE_URL"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo -e "${GREEN}  Setup complete — repo at: $REPO_DIR ${RESET}"
echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo ""
echo "Quick reference:"
echo "  git st                # short status"
echo "  git lg                # visual branch graph"
echo "  git last              # last commit with stats"
echo "  git add -p            # interactive staging (recommended)"
echo "  git commit -m 'msg'   # commit"
echo "  git push              # push to remote"
echo "  git undo              # undo last commit (keep changes)"
