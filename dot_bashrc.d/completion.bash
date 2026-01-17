# 補完設定
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
  fi
fi

# ディレクトリ移動
shopt -s cdspell
shopt -s autocd 2>/dev/null || true
