#!/usr/bin/env bash
# Code quality checks

set -uo pipefail
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARNINGS++)); }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "═══════════════════════════════════════════════════════════"
echo "  Code Quality Validation"
echo "═══════════════════════════════════════════════════════════"

src_files=$(find . -name '*.swift' -not -path './BuildTrack.xcodeproj/*' -not -path './BuildTrack.xcworkspace/*' -not -path './.git/*' -not -path './scripts/*')

info "Checking for TODO/FIXME/HACK/XXX comments..."
count=$(grep -n 'TODO\|FIXME\|HACK\|XXX' $src_files 2>/dev/null | wc -l)
if (( count > 0 )); then
  warn "$count TODO/FIXME/HACK/XXX comments found"
  grep -n 'TODO\|FIXME\|HACK\|XXX' $src_files | head -5
else
  pass "No TODO/FIXME/HACK/XXX comments"
fi

info "Checking for print() statements..."
count=$(grep -n 'print(' $src_files 2>/dev/null | wc -l)
if (( count > 0 )); then
  warn "$count print() statements found (consider OSLog for production)"
  grep -n 'print(' $src_files | head -5
else
  pass "No print() statements"
fi

info "Checking for force unwraps..."
try_force=$(grep -n 'try!' $src_files 2>/dev/null | wc -l)
as_force=$(grep -n ' as!' $src_files 2>/dev/null | wc -l)
if (( try_force > 0 )); then
  warn "$try_force force unwraps with try!"
  grep -n 'try!' $src_files | head -3
fi
if (( as_force > 0 )); then
  warn "$as_force force unwraps with as!"
  grep -n ' as!' $src_files | head -3
fi
if (( try_force == 0 && as_force == 0 )); then
  pass "No force unwraps found"
fi

info "Checking for fatalError..."
count=$(grep -n 'fatalError' $src_files 2>/dev/null | wc -l)
if (( count > 0 )); then
  warn "$count fatalError calls found"
  grep -n 'fatalError' $src_files | head -3
else
  pass "No fatalError calls"
fi

info "Checking for hardcoded secrets..."
secret_patterns=('eyJhbGciOiJIUzI1Ni' 'api_key' 'apikey' 'secret' 'token' 'bearer ')
for pattern in "${secret_patterns[@]}"; do
  matches=$(grep -in "$pattern" $src_files 2>/dev/null | grep -v '// ' | grep -v 'Config-' | grep -v 'SupabaseManager.swift' | grep -v 'userMetadata' | head -3)
  if [[ -n "$matches" ]]; then
    warn "Potential hardcoded secret pattern '$pattern':"
    echo "$matches"
  fi
done

info "Checking Sendable conformance..."
count=$(grep -rn 'Sendable' --include='*.swift' . | grep -v BuildTrack.xcodeproj | grep -v '.git/' | wc -l)
if (( count > 0 )); then
  pass "Found $count Sendable references"
else
  warn "No Sendable conformance found"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
if (( ERRORS == 0 )); then
  echo -e "${GREEN}✓ QUALITY CHECK PASSED${NC} — $WARNINGS warnings"
  exit 0
else
  echo -e "${RED}✗ QUALITY CHECK FAILED${NC} — $ERRORS errors, $WARNINGS warnings"
  exit 1
fi
