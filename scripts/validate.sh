#!/usr/bin/env bash
# Pre-PR checks for the promptify skill. Exits 1 on any failure.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
ok()   { printf '  ok   %s\n' "$1"; }
err()  { printf '  FAIL %s\n' "$1"; fail=1; }

echo "SKILL.md frontmatter"
fm="$(awk 'NR==1 && $0!="---"{exit 1} NR>1 && $0=="---"{exit} NR>1{print}' SKILL.md)" || { err "no frontmatter"; fm=""; }
name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p')"
[ "$name" = "promptify" ] && ok "name = promptify" || err "name is '$name' (expected promptify)"
printf '%s' "$name" | grep -qE '^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$' && ok "name pattern" || err "name pattern"
desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p')"
[ -n "$desc" ] && ok "description present (${#desc} chars)" || err "description missing"
[ "${#desc}" -le 1536 ] && ok "description <= 1536 chars" || err "description too long"
printf '%s\n' "$fm" | grep -q '^metadata:' && printf '%s\n' "$fm" | grep -qE '^  version:' && ok "metadata.version" || err "metadata.version missing"
printf '%s\n' "$fm" | grep -q '^allowed-tools:.*snapshot.sh' && ok "allowed-tools pre-approves snapshot.sh" || err "allowed-tools lacks snapshot.sh"
grep -q '^!`${CLAUDE_SKILL_DIR}/scripts/snapshot.sh`' SKILL.md && ok "snapshot injection line" || err "snapshot injection line missing/misplaced"
grep -q '\$ARGUMENTS' SKILL.md && ok "\$ARGUMENTS placeholder" || err "\$ARGUMENTS missing"
lines=$(wc -l < SKILL.md | tr -d ' '); [ "$lines" -le 200 ] && ok "SKILL.md length ${lines} lines" || err "SKILL.md is ${lines} lines (keep it short; move detail to references/)"

echo "Referenced files"
for f in references/principles.md references/model-notes.md references/repo-grounding.md references/examples.md templates/prompt-template.md; do
  grep -q "$f" SKILL.md || err "$f not mentioned in SKILL.md"
  [ -f "$f" ] && ok "$f" || err "$f missing"
done

echo "Versions in sync"
v_fm="$(printf '%s\n' "$fm" | sed -n 's/^  version:[[:space:]]*//p')"
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  v_j="$(grep -oE '"version":[[:space:]]*"[^"]+"' "$j" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
  [ "$v_j" = "$v_fm" ] && ok "$j version $v_j" || err "$j version '$v_j' != frontmatter '$v_fm'"
done

echo "snapshot.sh"
bash -n scripts/snapshot.sh && ok "syntax" || err "syntax error"
[ -x scripts/snapshot.sh ] && ok "executable" || err "not executable (chmod +x)"
tmp="$(mktemp -d)"
( cd "$tmp" && CLAUDE_PROJECT_DIR="$tmp" bash "$OLDPWD/scripts/snapshot.sh" >/dev/null 2>&1 ) && ok "exit 0 in empty dir" || err "non-zero in empty dir"
( cd "$tmp" && git init -q && touch a && git add a && git -c user.name=t -c user.email=t@t commit -qm x && CLAUDE_PROJECT_DIR="$tmp" bash "$OLDPWD/scripts/snapshot.sh" 2>/dev/null | grep -q 'branch=' ) && ok "reports branch in a git repo" || err "git repo probe"
( CLAUDE_PROJECT_DIR="$PWD" bash scripts/snapshot.sh >/dev/null 2>&1 ) && ok "exit 0 here" || err "non-zero here"
rm -rf "$tmp"

if command -v claude >/dev/null 2>&1; then
  echo "claude plugin validate"
  claude plugin validate . --strict >/dev/null 2>&1 && ok "marketplace manifest (strict)" || err "claude plugin validate . --strict"
  c="$(mktemp -d)"; cp -R .claude-plugin SKILL.md scripts references templates "$c"/ && rm -f "$c/.claude-plugin/marketplace.json"
  claude plugin validate "$c" --strict >/dev/null 2>&1 && ok "plugin manifest + skill (strict)" || err "plugin manifest validation"
  rm -rf "$c"
else
  echo "claude CLI not found — skipping plugin validation"
fi

[ $fail -eq 0 ] && echo "all checks passed" || { echo "some checks failed"; exit 1; }
