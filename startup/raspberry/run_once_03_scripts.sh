#!/bin/bash
{{- if eq .chezmoi.os "linux" -}}

set -eufo pipefail

# miseのインストール
if ! command -v mise &> /dev/null; then
  echo "📦 Installing mise..."
  curl https://mise.run | sh
else
  echo "✅ mise already installed."
fi

# Node.jsのインストール（mise経由）
if ! command -v node &> /dev/null; then
  echo "📦 Installing Node.js via mise..."
  mise install -y node@24.12
else
  echo "✅ Node.js already installed."
fi

# Claude Codeのインストール
if ! command -v claude &> /dev/null; then
  echo "📦 Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
else
  echo "✅ Claude Code already installed."
fi

# codexのインストール
if ! command -v codex &> /dev/null; then
  echo "📦 Installing codex..."
  npm install -g @openai/codex
else
  echo "✅ codex already installed."
fi

# chezmoiのインストール
if ! command -v chezmoi &> /dev/null; then
  echo "📦 Installing chezmoi..."
  curl -fsSL https://chezmoi.io/get.sh | bash
else
  echo "✅ chezmoi already installed."
fi

echo "✅ All tools installed successfully."
{{- end -}}
