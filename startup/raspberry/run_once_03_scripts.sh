#!/bin/bash
{{- if eq .chezmoi.os "linux" -}}

set -eufo pipefail

# Claude Codeのインストール
if ! command -v claude &> /dev/null; then
  echo "📦 Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "✅ Claude Code already installed."
fi

# chezmoiのインストール
if ! command -v chezmoi &> /dev/null; then
  echo "📦 Installing chezmoi..."
  curl -fsSL https://chezmoi.io/get.sh | bash
else
  echo "✅ chezmoi already installed."
fi

{{- end -}}
