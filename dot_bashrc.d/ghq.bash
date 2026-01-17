# ghq + fzf でリポジトリ選択
# Note: zshのzleに相当する機能はbashにはないため、関数のみ提供

function ghqfzf() {
  local src
  src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.* 2>/dev/null || ls -la $(ghq root)/{}")
  if [ -n "$src" ]; then
    cd "$(ghq root)/$src" || return
  fi
}
