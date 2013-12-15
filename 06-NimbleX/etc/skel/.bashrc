PS1=":\w\`if [ \$? = 0 ]; then echo -e '\e[01;32m\\$'; else echo -e '\e[01;31m\\$'; fi\`\[\e[00m\] "

alias grep="grep --color=auto"
alias df="df -x squashfs"
alias ls="ls $LS_OPTIONS"

export PROMPT_DIRTRIM=3

PROMPT_COMMAND='echo -ne "\033k$HOSTNAME\033\\"'
