# Kimi CLI - Moonshot AI's CLI agent
# Comprehensive completions with context awareness

if (( ! $+commands[kimi] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_kimi_cache_dir="${ZSH_CACHE_DIR}/kimi"
mkdir -p "$_kimi_cache_dir"

# Get recent sessions
_kimi_sessions() {
  local cache_file="$_kimi_cache_dir/sessions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    # Check for session storage in ~/.kimi or similar
    local kimi_dir="${HOME}/.kimi"
    if [[ -d "$kimi_dir/sessions" ]]; then
      ls -t "$kimi_dir/sessions" 2>/dev/null | head -20 >| "$cache_file"
    fi
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get available models
_kimi_models() {
  local models=(
    'moonshot-v1-8k:Moonshot 8K context'
    'moonshot-v1-32k:Moonshot 32K context'
    'moonshot-v1-128k:Moonshot 128K context'
    'kimi-latest:Latest Kimi model'
    'kimi-k2:Kimi K2 model'
  )
  print -l "${models[@]}"
}

# Get mode options
_kimi_modes() {
  local modes=(
    'agent:Full agent mode with tool use'
    'chat:Simple chat mode'
    'code:Code-focused mode'
  )
  print -l "${modes[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_kimi() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Command subcommand completion
  if (( CURRENT == 2 )); then
    local commands=(
      'chat:Start interactive chat'
      'run:Run with prompt'
      'config:Manage configuration'
      'session:Manage sessions'
      'model:Model management'
      'help:Show help'
    )
    
    # Also complete global options
    if [[ "$cur" == -* ]]; then
      _kimi_global_options
    else
      _describe -t commands "kimi commands" commands
    fi
    return
  fi
  
  local cmd=$words[2]
  
  # Complete based on subcommand
  case "$cmd" in
    chat|run)
      _kimi_chat_options
      ;;
    config)
      _kimi_config_completion
      ;;
    session)
      _kimi_session_completion
      ;;
    model)
      _kimi_model_completion
      ;;
    *)
      _files
      ;;
  esac
}

_kimi_global_options() {
  local -a options
  options=(
    '(-V --version)'{-V,--version}'[Show version]'
    '--verbose[Print verbose information]'
    '--debug[Log debug information]'
    '(-w --work-dir)'{-w,--work-dir}'[Working directory]:directory:_files -/'
    '(-S --session)'{-S,--session}'[Session ID to resume]:session:_kimi_sessions'
    '(-C --continue)'{-C,--continue}'[Continue current session]'
    '--add-dir[Additional workspace directories]:directory:_files -/'
    '(-h --help)'{-h,--help}'[Show help]'
  )
  _describe -t options "global options" options
}

_kimi_chat_options() {
  local -a options
  options=(
    # Model selection
    '--model[Model to use]:model:_kimi_models'
    '--mode[Agent mode]:mode:_kimi_modes'
    
    # Input/Output
    '--prompt[Initial prompt]:prompt: '
    '--file[File to include]:file:_files'
    '--stdin[Read from stdin]'
    
    # Behavior
    '--no-tools[Disable tool use]'
    '--no-files[Disable file operations]'
    '--safe-mode[Safe mode with confirmations]'
    '--yolo[Auto-approve all actions]'
    
    # Context
    '--context[Context files]:files:_files'
    '--ignore[Ignore patterns]:patterns: '
    
    # Output
    '--output[Output file]:file:_files'
    '--format[Output format]:format:(text markdown json)'
    
    # Session
    '--new-session[Start new session]'
    '--save-session[Save session on exit]'
    
    # Help
    '(-h --help)'{-h,--help}'[Show help]'
  )
  
  # Add prompt suggestions if at end
  if (( CURRENT > 2 )) && [[ "$words[CURRENT]" != -* ]]; then
    _kimi_prompt_suggestions
  else
    _describe -t options "chat options" options
  fi
}

_kimi_config_completion() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  if (( CURRENT == 3 )); then
    local config_cmds=(
      'get:Get configuration value'
      'set:Set configuration value'
      'list:List all configuration'
      'reset:Reset to defaults'
      'init:Initialize configuration'
    )
    _describe -t commands "config commands" config_cmds
    return
  fi
  
  local config_cmd=$words[3]
  
  case "$config_cmd" in
    get|set)
      local keys=(
        'api.key:API key'
        'api.base_url:API base URL'
        'model.default:Default model'
        'agent.mode:Default agent mode'
        'agent.auto_confirm:Auto-confirm actions'
        'editor.default:Default editor'
        'output.format:Default output format'
        'session.save_dir:Session save directory'
      )
      _describe -t keys "config keys" keys
      ;;
    *)
      ;;
  esac
}

_kimi_session_completion() {
  if (( CURRENT == 3 )); then
    local session_cmds=(
      'list:List all sessions'
      'show:Show session details'
      'resume:Resume a session'
      'delete:Delete a session'
      'export:Export session'
      'import:Import session'
      'clean:Clean old sessions'
    )
    _describe -t commands "session commands" session_cmds
    return
  fi
  
  local session_cmd=$words[3]
  
  case "$session_cmd" in
    show|resume|delete|export)
      _kimi_sessions
      ;;
    import)
      _files
      ;;
    clean)
      local clean_opts=(
        '--older-than[Clean sessions older than]:duration: '
        '--keep-last[Keep last N sessions]:count: '
        '--dry-run[Show what would be deleted]'
      )
      _describe -t options "clean options" clean_opts
      ;;
  esac
}

_kimi_model_completion() {
  if (( CURRENT == 3 )); then
    local model_cmds=(
      'list:List available models'
      'info:Show model information'
      'default:Set default model'
    )
    _describe -t commands "model commands" model_cmds
    return
  fi
  
  local model_cmd=$words[3]
  
  case "$model_cmd" in
    info|default)
      _kimi_models
      ;;
  esac
}

_kimi_prompt_suggestions() {
  local -a suggestions
  suggestions=(
    '"Review this code"'
    '"Explain this function"'
    '"Refactor this code"'
    '"Write tests for this"'
    '"Optimize this code"'
    '"Debug this error"'
    '"Document this API"'
    '"Convert to TypeScript"'
    '"Add error handling"'
    '"Implement this feature"'
  )
  
  _describe -t suggestions "prompt suggestions" suggestions
}

compdef _kimi kimi

# ============================================================
# ALIASES
# ============================================================

alias k='kimi'
alias kc='kimi chat'
alias kcc='kimi chat --continue'
alias kr='kimi run'
alias ks='kimi session'
alias ksl='kimi session list'
alias ksr='kimi session resume'

# Mode-specific aliases
alias ka='kimi --mode agent'
alias kcode='kimi --mode code'
alias kchat='kimi --mode chat'

# Quick action aliases
alias kfix='kimi run "Fix this code"'
alias kexplain='kimi run "Explain this"'
alias ktest='kimi run "Write tests"'
alias kdoc='kimi run "Add documentation"'
alias krefactor='kimi run "Refactor this"'
alias koptimize='kimi run "Optimize this"'

# Model-specific aliases
alias kk2='kimi --model kimi-k2'
alias k8k='kimi --model moonshot-v1-8k'
alias k32k='kimi --model moonshot-v1-32k'
alias k128k='kimi --model moonshot-v1-128k'
