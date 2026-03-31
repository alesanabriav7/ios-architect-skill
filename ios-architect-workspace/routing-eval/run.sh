#!/usr/bin/env bash
# Routing eval: verifies each prompt picks the right skill.
# Uses claude -p in classification mode — no code generation, ~2s per case.
# Run from any directory: bash ios-architect-workspace/routing-eval/run.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CASES_FILE="$SCRIPT_DIR/routing-cases.json"

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
current_group=""

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

while IFS=$'\t' read -r group prompt expected; do
  if [[ "$group" != "$current_group" ]]; then
    echo ""
    echo "$group"
    current_group="$group"
  fi
  check "$prompt" "$expected"
done < <(jq -r '.cases[] | [.group, .prompt, .expected_skill] | @tsv' "$CASES_FILE")

echo ""
total=$((pass + fail))
echo "Results: $pass/$total passed"
[[ $fail -gt 0 ]] && exit 1 || exit 0
