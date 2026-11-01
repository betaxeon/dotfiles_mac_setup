autoload -Uz compinit
compinit
typeset -U path
# Preserve workplace-provided tools ahead of optional personal installations.
for _dotfiles_bin in "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/node@24/bin" \
  "$HOME/.codebuddy/bin" "$HOME/.lmstudio/bin" "$HOME/.local/bin"; do
  [[ ! -d "$_dotfiles_bin" ]] || path+=("$_dotfiles_bin")
done
unset _dotfiles_bin
