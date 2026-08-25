#!/usr/bin/env bash
# lisp-mind profile — pi-lisptc + optional cache extension.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "Profile: lisp-mind"
echo "ROOT=$ROOT"
echo "Wire: pi -e $ROOT/src/extension -e /path/to/opencode-go-cache"
# pi -e "$ROOT/src/extension" "$@"
