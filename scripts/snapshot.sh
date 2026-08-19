#!/usr/bin/env bash
# Read-only snapshot of the current repo, injected into SKILL.md before the skill
# content reaches Claude. Must never exit non-zero (a failing injected command
# aborts the whole skill invocation), so every probe is guarded and the script
# ends with `exit 0`.

cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || true

echo "cwd: $(pwd)"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git branch --show-current 2>/dev/null)"
  last="$(git log -1 --format='%h %s' 2>/dev/null)"
  changed="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
  echo "git: branch=${branch:-detached} | uncommitted=${changed} | last=${last}"
else
  echo "git: not a repository"
fi

echo "top-level: $(ls -A 2>/dev/null | head -80 | tr '\n' ' ')"

for f in CLAUDE.md .claude/CLAUDE.md AGENTS.md CONTRIBUTING.md README.md docs/README.md; do
  [ -f "$f" ] && echo "doc: $f"
done

[ -d .claude/skills ] && echo "project skills: $(ls .claude/skills 2>/dev/null | tr '\n' ' ')"
[ -d .claude/agents ] && echo "project agents: $(ls .claude/agents 2>/dev/null | sed 's/\.md$//' | tr '\n' ' ')"
[ -d .claude/commands ] && echo "project commands: $(ls .claude/commands 2>/dev/null | sed 's/\.md$//' | tr '\n' ' ')"
[ -f .claude/settings.json ] && echo "doc: .claude/settings.json (hooks/permissions may apply)"

for f in package.json pnpm-workspace.yaml turbo.json nx.json pyproject.toml setup.py requirements.txt Pipfile \
         Cargo.toml go.mod Gemfile Package.swift pubspec.yaml build.gradle build.gradle.kts pom.xml \
         composer.json mix.exs Makefile justfile Taskfile.yml docker-compose.yml Dockerfile; do
  [ -f "$f" ] && echo "manifest: $f"
done

ls -d -- *.xcodeproj *.xcworkspace 2>/dev/null | sed 's/^/xcode: /'
[ -d ios ] || [ -d android ] && ls -d ios android 2>/dev/null | sed 's/^/mobile dir: /'

if [ -f package.json ]; then
  scripts="$(grep -oE '"(test|test:[a-z0-9:-]+|build|lint|typecheck|type-check|check|dev|start|e2e|format)"[[:space:]]*:' package.json 2>/dev/null | tr -d '" :' | sort -u | tr '\n' ' ')"
  [ -n "$scripts" ] && echo "npm scripts: $scripts"
fi
[ -f pyproject.toml ] && grep -qE '^\[tool\.(pytest|ruff|mypy|black)' pyproject.toml 2>/dev/null && \
  echo "python tooling: $(grep -oE '^\[tool\.(pytest|ruff|mypy|black)[^]]*\]' pyproject.toml | tr '\n' ' ')"
[ -f Makefile ] && echo "make targets: $(grep -oE '^[a-zA-Z0-9_-]+:' Makefile 2>/dev/null | tr -d ':' | head -15 | tr '\n' ' ')"

tdirs="$(ls -d test tests __tests__ spec src/test Tests UITests e2e cypress playwright 2>/dev/null | sort -fu | tr '\n' ' ')"
[ -n "$tdirs" ] && echo "test dirs: $tdirs"

exit 0
