# socket-dev shell rc. The zellij shell pane starts `bash --rcfile` on this
# file; the attach shell itself reads no startup files (Minimal runs it as
# `bash --noprofile -l`), which is why this is not a patched ~/.bashrc.

# fd lists files faster than find and honours .gitignore; --hidden keeps
# dotfiles like .github/ and .config/ in the list, minus .git itself.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
export BAT_THEME="${BAT_THEME:-ansi}"

# Ctrl-R history search, Ctrl-T file picker, Alt-C cd into a directory, and
# `**<Tab>` completion.
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

alias vi=vim
alias ll='ls -la'
