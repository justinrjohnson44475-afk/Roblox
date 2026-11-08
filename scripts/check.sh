#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
.tools/stylua --check src tests scripts/inspect-place.luau scripts/bake-world.luau scripts/ascension/*.luau
.tools/lune run tests/run.luau | tee build/test-results.txt
python3 -m unittest discover -s tests -p 'test_*.py' -v
.tools/lune run scripts/bake-world.luau
.tools/rojo build default.project.json -o build/Riftwake.rbxl
.tools/rojo build default.project.json -o build/Riftwake.rbxlx
.tools/lune run scripts/inspect-place.luau | tee build/place-inspection.txt
python3 scripts/ascension/verify.py
.tools/rojo build ascension.project.json -o build/Ascension-Signature.rbxl
.tools/rojo build ascension.project.json -o build/Ascension-Signature.rbxlx
cp build/Ascension-Signature.rbxl build/Riftwake-Movement-v2.rbxl
.tools/lune run scripts/ascension/inspect.luau | tee build/ascension-inspection.txt
python3 scripts/publish.py --place-id 1 --file build/Riftwake.rbxl
sha256sum build/Riftwake.rbxl build/Riftwake.rbxlx build/Ascension-Signature.rbxl build/Ascension-Signature.rbxlx build/Riftwake-Movement-v2.rbxl | tee build/SHA256SUMS
