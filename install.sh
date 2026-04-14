#!/usr/bin/env bash

REPO_URL="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/vibe-guard-skills/main"
SKILLS=("vibe-guard" "vibe-check" "vibe-secure" "vibe-explain")
FAILED=()

echo ""
echo "╔════════════════════════════════════╗"
echo "║  Installing vibe-guard-skills      ║"
echo "╚════════════════════════════════════╝"
echo ""

# Detect install location — global first, then project-local
if [ -d "$HOME/.claude" ]; then
  INSTALL_DIR="$HOME/.claude/skills"
  echo "→ Global install: ~/.claude/skills/"
elif [ -d ".claude" ]; then
  INSTALL_DIR=".claude/skills"
  echo "→ Project-local install: .claude/skills/"
else
  echo "❌ Claude Code config directory not found."
  echo "   Install Claude Code first: https://code.claude.com"
  exit 1
fi

mkdir -p "$INSTALL_DIR"

# Download each skill (continue on failure, report at end)
for skill in "${SKILLS[@]}"; do
  echo -n "  Downloading $skill... "
  if curl -fsSL "$REPO_URL/skills/$skill.md" -o "$INSTALL_DIR/$skill.md" 2>/dev/null; then
    echo "✓"
  else
    echo "✗ FAILED"
    FAILED+=("$skill")
  fi
done

echo ""

if [ ${#FAILED[@]} -eq 0 ]; then
  echo "✅ vibe-guard-skills installed to: $INSTALL_DIR"
  echo ""
  echo "Available skills:"
  echo "  /vibe-guard   — Full safety check (run before every push)"
  echo "  /vibe-check   — Production resilience only"
  echo "  /vibe-secure  — Security audit only"
  echo "  /vibe-explain — Comprehension / cognitive debt only"
  echo ""
  echo "Skills load automatically in your next Claude Code session."
  echo "Type /vibe-guard in Claude Code to get started."
else
  echo "⚠️  Some skills failed to download:"
  for s in "${FAILED[@]}"; do echo "   - $s"; done
  echo ""
  echo "Successfully installed: $(( ${#SKILLS[@]} - ${#FAILED[@]} ))/${#SKILLS[@]} skills"
  echo "Check your internet connection and try again."
  exit 1
fi
echo ""
