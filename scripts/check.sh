#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
.tools/stylua --check src tests scripts/inspect-place.luau
.tools/lune run tests/run.luau | tee build/test-results.txt
python3 -m unittest discover -s tests -p 'test_*.py' -v
.tools/rojo build default.project.json -o build/Harborlight.rbxl
.tools/rojo build default.project.json -o build/Harborlight.rbxlx
.tools/lune run scripts/inspect-place.luau | tee build/place-inspection.txt
python3 scripts/publish.py --place-id 1 --file build/Harborlight.rbxl
sha256sum build/Harborlight.rbxl build/Harborlight.rbxlx | tee build/SHA256SUMS
