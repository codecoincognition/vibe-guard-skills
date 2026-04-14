#!/usr/bin/env bash
set -e

REPO_URL="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/vibe-guard-skills/main"
SKILLS=("vibe-guard" "vibe-check" "vibe-secure" "vibe-explain")

echo ""
echo "╔══════════════════════════════════╗"
echo "║     Installing vibe-guard-skills  ║"
echo "╚══════════════════════════════════╝"
echo ""

# Detect install location
if [ -d ".claude" ]; then
  INSTALL_DIR=".claude/skills"
  echo "→ Project-local install detected (.claude/skills/)"
elif [ -d "$HOME/.claude" ]; then
  INSTALL_DIR="$HOME/.claude/skills"
  echo "→ Global install detected (~/.claude/skills/)"
else
  echo "Error: Claude Code config directory not found."
  echo "Make sure Claude Code is installed: https://code.claude.com"
  exit 1
fi

mkdir -p "$INSTALL_DIR"

# Download each skill
for skill in "${SKILLS[@]}"; do
  echo "  Downloading $skill..."
  curl -fsSL "$REPO_URL/skills/$skill.md" -o "$INSTALL_DIR/$skill.md"
  echo "  ✓ $skill installed"
done

echo ""
echo "✅ vibe-guard-skills installed successfully!"
echo ""
echo "Available skills:"
echo "  /vibe-guard   — Full safety check (run this before every push)"
echo "  /vibe-check   — Production resilience only"
echo "  /vibe-secure  — Security audit only"
echo "  /vibe-explain — Comprehension / cognitive debt only"
echo ""
echo "Usage: Type /vibe-guard in Claude Code at the end of a coding session."
echo ""
