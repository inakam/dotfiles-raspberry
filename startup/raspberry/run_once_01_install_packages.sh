#!/bin/bash
{{- if eq .chezmoi.os "linux" -}}

# packages.listのハッシュ値をコメントとして埋め込む
# packages.list hash: {{ include "dot_config/apt/packages.list" | sha256sum }}

set -eufo pipefail

echo "📦 Installing apt packages..."

# パッケージリストの更新
sudo apt-get update

# パッケージのインストール
xargs -a "$HOME/.config/apt/packages.list" sudo apt-get install -y

echo "✅ apt packages installed successfully."
{{- end -}}
