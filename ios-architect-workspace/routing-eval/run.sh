#!/usr/bin/env bash
# Routing eval: verifies each prompt picks the right skill.
# Uses claude -p in classification mode — no code generation, ~2s per case.
# Run from any directory: bash ios-architect-workspace/routing-eval/run.sh

set -euo pipefail
SKILLS_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Build system prompt from actual SKILL.md descriptions
build_system_prompt() {
  echo "You are a routing classifier for iOS development skills. Given a user request, reply with ONLY the skill name that best handles it. No explanation, no punctuation — just the skill name."
  echo ""
  echo "Available skills:"
  for skill in ios-architect ios-persistence ios-testing ios-visual ios-platform ios-design-system; do
    local desc
    desc=$(awk '/^description:/{found=1; next} found && /^[a-z]/{exit} found{print}' "$SKILLS_DIR/$skill/SKILL.md" | sed 's/^  //' | tr '\n' ' ')
    echo ""
    echo "$skill: $desc"
  done
}

SYSTEM_PROMPT=$(build_system_prompt)

pass=0; fail=0

check() {
  local prompt="$1" expected="$2"
  local got
  got=$(echo "$prompt" | claude -p --disable-slash-commands --system-prompt "$SYSTEM_PROMPT" --model claude-haiku-4-5-20251001 2>/dev/null | grep -Eo 'ios-(architect|persistence|testing|visual|platform|design-system)' | head -1)
  if [[ "$got" == "$expected" ]]; then
    echo "  ✓  $prompt"
    pass=$((pass + 1))
  else
    echo "  ✗  $prompt"
    echo "     expected: $expected  got: $got"
    fail=$((fail + 1))
  fi
}

echo ""
echo "ios-architect"
check "Create a favorites feature for the app" "ios-architect"
check "Add a settings screen where users can edit their profile" "ios-architect"
check "Agrega una pantalla de historial de pagos" "ios-architect"
check "How should I structure the analytics service shared by multiple features?" "ios-architect"

echo ""
echo "ios-persistence"
check "Add a new column to store the user's avatar URL" "ios-persistence"
check "The transaction list should refresh automatically when data changes" "ios-persistence"
check "The data isn't persisting between app launches" "ios-persistence"
check "Necesito guardar el progreso del usuario localmente" "ios-persistence"

echo ""
echo "ios-testing"
check "Write tests for the WorkoutViewModel" "ios-testing"
check "The app crashes randomly, I think it's a threading issue" "ios-testing"
check "How do I create a fake version of the repository for tests?" "ios-testing"
check "I'm getting a Sendable warning and I don't know how to fix it" "ios-testing"

echo ""
echo "ios-visual"
check "Does the home screen match the Figma design?" "ios-visual"
check "Something looks off after my last change, can you check?" "ios-visual"
check "Run visual regression before the PR" "ios-visual"

echo ""
echo "ios-platform"
check "Set up the API client to call our backend" "ios-platform"
check "The token expires and the app doesn't refresh it automatically" "ios-platform"
check "Add deep link support so users can share a link to a specific item" "ios-platform"

echo ""
echo "ios-design-system"
check "Create a reusable card component for the design system" "ios-design-system"
check "Add a Liquid Glass effect to the navigation bar" "ios-design-system"

echo ""
echo "keywords"
check "add a feature for tracking sleep" "ios-architect"
check "quiero agregar una feature de favoritos" "ios-architect"
check "actualiza el design system con los nuevos tokens" "ios-design-system"
check "set up SQLite for the project" "ios-persistence"
check "configura la base de datos" "ios-persistence"
check "necesito una base de datos local" "ios-persistence"
check "cache the API responses locally" "ios-persistence"
check "add caching to reduce network calls" "ios-persistence"
check "implementa un cache de imágenes" "ios-persistence"

echo ""
echo "boundary"
check "Add offline support to the Notes feature" "ios-architect"
check "add offline mode to the app" "ios-architect"
check "quiero que funcione sin conexión" "ios-architect"
# skipped: "cache data so it works offline" — non-deterministic, both ios-architect and ios-persistence are valid
# skipped: "The button color is wrong" — non-deterministic, both ios-visual and ios-design-system are valid
check "Quiero que la app funcione sin internet" "ios-architect"

echo ""
total=$((pass + fail))
echo "Results: $pass/$total passed"
[[ $fail -gt 0 ]] && exit 1 || exit 0
