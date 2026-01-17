# snap
export PATH="/snap/bin:$PATH"

# local bin
export PATH="$HOME/.local/bin:$PATH"

# uv/cargo環境（存在する場合のみ）
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# rbenv
if [ -d ~/.rbenv ]; then
  export PATH=${HOME}/.rbenv/bin:${PATH}
  eval "$(rbenv init -)"
fi

# moonbit
export PATH="$HOME/.moon/bin:$PATH"
