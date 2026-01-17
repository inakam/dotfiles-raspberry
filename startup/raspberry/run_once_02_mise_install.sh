#!/bin/bash
{{- if eq .chezmoi.os "linux" -}}

# mise config.tomlのハッシュ値をコメントとして埋め込む
# mise config.toml hash: {{ include "dot_config/mise/config.toml" | sha256sum }}

set -eufo pipefail

if command -v mise &> /dev/null; then
  echo "📦 Installing mise tools..."
  mise install
  echo "✅ mise tools installed successfully."
else
  echo "⚠️  mise not found. Skipping..."
fi

{{- end -}}
