#!/usr/bin/env bash
# Giải mã mọi .env.age (agenix) -> .env.
#   ./decrypt-env.sh             # giải mã tại chỗ: <proj>/.env.age -> <proj>/.env
#   ./decrypt-env.sh <TARGET>    # giải mã thẳng vào repo Onschool: <TARGET>/<proj>/.env
# Identity mặc định ~/.ssh/id_ed25519 (đổi bằng AGENIX_IDENTITY).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-$here}"
id="${AGENIX_IDENTITY:-$HOME/.ssh/id_ed25519}"

cd "$here"
find . -name '.env.age' -not -path '*/.git/*' | while read -r age; do
  age="${age#./}"                              # agenix khớp rule trong secrets.nix không có './'
  rel="${age%.age}"                            # SRM/general/.env.age -> SRM/general/.env
  out="$target/$rel"
  mkdir -p "$(dirname "$out")"
  agenix -d "$age" -i "$id" > "$out"
  echo "  -> $out"
done
