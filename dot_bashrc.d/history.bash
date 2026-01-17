# 履歴設定
HISTFILE=$HOME/.bash_history
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:ignoreboth:erasedups
shopt -s histappend
# 複数セッションで履歴を即時共有
history -a
history -c
history -r
