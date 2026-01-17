#!/bin/bash
{{- if eq .chezmoi.os "linux" -}}

set -eufo pipefail

# neovim (snap)のインストール
if ! command -v nvim &> /dev/null; then
  echo "📦 Installing Neovim via snap..."
  sudo snap install nvim --classic
else
  echo "✅ Neovim already installed."
fi

# nvmのインストール
if [ ! -d "$HOME/.nvm" ]; then
  echo "📦 Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  # nvmを有効化
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  echo "✅ nvm already installed."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Node.js (LTS)のインストール
if ! command -v node &> /dev/null; then
  echo "📦 Installing Node.js LTS..."
  nvm install --lts
  nvm use --lts
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
  npm install -g @anthropic-ai/claude-code-explorer
else
  echo "✅ codex already installed."
fi

# task-masterのインストール
if ! command -v task-master &> /dev/null; then
  echo "📦 Installing task-master..."
  npm install -g @anthropic/task-master
else
  echo "✅ task-master already installed."
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
