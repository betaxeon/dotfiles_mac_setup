# This file is sourced after the existing workplace shell configuration.
typeset _dotfiles_root="${${(%):-%x}:A:h:h:h}"
source "$_dotfiles_root/.zshrc"
source "$_dotfiles_root/app-configs/shell/aliases.zsh"

if command -v brew >/dev/null 2>&1; then
  typeset _dotfiles_brew_prefix="$(brew --prefix)"
  if [[ -r "$_dotfiles_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$_dotfiles_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    bindkey '^f' autosuggest-accept
  fi
  if [[ -r "$_dotfiles_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$_dotfiles_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
  unset _dotfiles_brew_prefix
fi
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$_dotfiles_root/app-configs/starship.toml}"
  eval "$(starship init zsh)"
fi
if command -v nvim >/dev/null 2>&1 && [[ -z "${EDITOR:-}" ]]; then
  export EDITOR=nvim
fi
[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"
unset _dotfiles_root
