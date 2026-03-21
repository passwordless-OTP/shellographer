# shellographer - oh-my-zsh plugin for discoverable CLI aliases
# https://github.com/passwordless-OTP/shellographer

# Guard: Don't load twice
(( $+_SHELLOGRAPHER_LOADED )) && return 0
typeset -gr _SHELLOGRAPHER_LOADED=1

# Get plugin directory
0=${(%):-%N}
local _sdir=${0:A:h}

# Load shared libraries (optional - plugins have fallbacks)
[[ -f "$_sdir/lib/alias-helper.zsh" ]] && source "$_sdir/lib/alias-helper.zsh"
[[ -f "$_sdir/lib/cache-helper.zsh" ]] && source "$_sdir/lib/cache-helper.zsh"
[[ -f "$_sdir/lib/caps.zsh" ]] && source "$_sdir/lib/caps.zsh"

# Determine which plugins to load
# Users can override: SHELLOGRAPHER_PLUGINS="wrangler gh docker"
local _plugins=(${(s: :)SHELLOGRAPHER_PLUGINS:-wrangler gh docker})

# Load each plugin
for _plugin in $_plugins; do
  local _plugin_file="$_sdir/plugins/$_plugin/$_plugin.plugin.zsh"
  local _loaded_var="_SHELLOGRAPHER_PLUGIN_${(U)_plugin}"
  
  # Skip if already loaded by this script
  (( ${(P)+_loaded_var} )) && continue
  
  if [[ -f "$_plugin_file" ]]; then
    typeset -g "${_loaded_var}=1"
    source "$_plugin_file"
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Loaded: $_plugin" >&2
  else
    (( SHELLOGRAPHER_DEBUG )) && print "[shellographer] Warning: Plugin '$_plugin' not found at $_plugin_file" >&2
  fi
done

# Clean up temporary variables
unset _sdir _plugin _plugin_file _plugins _loaded_var
