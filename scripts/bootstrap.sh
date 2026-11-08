#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo 'This installer targets Linux x86_64. On macOS/Windows use aftman install with aftman.toml.' >&2
  exit 1
fi
mkdir -p .tools/archives
curl --fail --silent --show-error --location --max-time 120 \
  https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip -o .tools/archives/rojo.zip
curl --fail --silent --show-error --location --max-time 120 \
  https://github.com/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip -o .tools/archives/lune.zip
curl --fail --silent --show-error --location --max-time 120 \
  https://github.com/JohnnyMorganz/StyLua/releases/download/v2.6.0/stylua-linux-x86_64.zip -o .tools/archives/stylua.zip
(cd .tools/archives && sha256sum --check ../../scripts/tools.sha256)
for tool in rojo lune stylua; do
  unzip -oq ".tools/archives/$tool.zip" -d .tools
  chmod +x ".tools/$tool"
done
.tools/rojo --version
.tools/lune --version
.tools/stylua --version
