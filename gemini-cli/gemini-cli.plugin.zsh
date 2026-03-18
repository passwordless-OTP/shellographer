# Gemini CLI - Google's AI CLI
# Comprehensive completions with context awareness

if (( ! $+commands[gemini] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_gemini_cache_dir="${ZSH_CACHE_DIR}/gemini"
mkdir -p "$_gemini_cache_dir"

# Get recent sessions
_gemini_sessions() {
  local cache_file="$_gemini_cache_dir/sessions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    gemini --list-sessions 2>/dev/null | head -20 >| "$cache_file"
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get available extensions
_gemini_extensions() {
  local cache_file="$_gemini_cache_dir/extensions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    gemini --list-extensions 2>/dev/null | awk '{print $1}' >| "$cache_file"
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get available models
_gemini_models() {
  local models=(
    'gemini-2.5-pro:Gemini 2.5 Pro'
    'gemini-2.0-flash:Gemini 2.0 Flash'
    'gemini-2.0-flash-lite:Gemini 2.0 Flash Lite'
    'gemini-1.5-pro:Gemini 1.5 Pro'
    'gemini-1.5-flash:Gemini 1.5 Flash'
    'gemini-1.5-flash-8b:Gemini 1.5 Flash 8B'
    'gemini-exp:Experimental model'
  )
  print -l "${models[@]}"
}

# Get approval modes
_gemini_approval_modes() {
  local modes=(
    'default:Prompt for approval'
    'auto_edit:Auto-approve edits'
    'yolo:Auto-approve all'
    'plan:Read-only mode'
  )
  print -l "${modes[@]}"
}

# Get skills
_gemini_skills() {
  local skills=(
    'code:Code generation and editing'
    'debug:Debugging assistance'
    'explain:Code explanation'
    'test:Test generation'
    'doc:Documentation'
    'review:Code review'
  )
  print -l "${skills[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_gemini() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # First level - subcommands or options
  if (( CURRENT == 2 )); then
    if [[ "$cur" == -* ]]; then
      _gemini_global_options
    else
      local commands=(
        'mcp:Manage MCP servers'
        'extensions:Manage extensions'
        'extension:Alias for extensions'
        'skills:Manage agent skills'
        'skill:Alias for skills'
        'help:Show help'
      )
      
      # Check if it's a query (default behavior)
      _describe -t commands "gemini commands" commands
      
      # Also suggest that any other input is a query
      if [[ -n "$cur" ]]; then
        _message "or enter a prompt query"
      fi
    fi
    return
  fi
  
  local cmd=$words[2]
  
  # Complete based on subcommand
  case "$cmd" in
    mcp)
      _gemini_mcp_completion
      ;;
    extensions|extension)
      _gemini_extensions_completion
      ;;
    skills|skill)
      _gemini_skills_completion
      ;;
    *)
      # For interactive mode with prompt
      if [[ "$cur" == -* ]]; then
        _gemini_global_options
      else
        _gemini_prompt_suggestions
      fi
      ;;
  esac
}

_gemini_global_options() {
  local -a options
  options=(
    # Debug
    '(-d --debug)'{-d,--debug}'[Run in debug mode]'
    
    # Model
    '(-m --model)'{-m,--model}'[Model to use]:model:_gemini_models'
    
    # Mode
    '(-p --prompt)'{-p,--prompt}'[Non-interactive mode]:prompt: '
    '(-i --prompt-interactive)'{-i,--prompt-interactive}'[Execute and continue interactive]:prompt: '
    
    # Sandbox
    '(-s --sandbox)'{-s,--sandbox}'[Run in sandbox]'
    
    # Approval mode
    '--approval-mode[Approval mode]:mode:_gemini_approval_modes'
    '(-y --yolo)'{-y,--yolo}'[Auto-approve all (YOLO mode)]'
    
    # Policy
    '--policy[Policy files]:files:_files'
    
    # Extensions
    '(-e --extensions)'{-e,--extensions}'[Extensions to use]:extensions:_gemini_extensions'
    '(-l --list-extensions)'{-l,--list-extensions}'[List available extensions]'
    
    # Resume
    '(-r --resume)'{-r,--resume}'[Resume previous session]:session:_gemini_sessions'
    '--list-sessions[List available sessions]'
    
    # Experimental
    '--experimental-acp[Start in ACP mode]'
    '--allowed-mcp-server-names[Allowed MCP servers]:servers: '
    '--allowed-tools[Allowed tools]:tools: '
    
    # Help
    '(-h --help)'{-h,--help}'[Show help]'
  )
  
  _describe -t options "gemini options" options
}

_gemini_mcp_completion() {
  if (( CURRENT == 3 )); then
    local mcp_cmds=(
      'list:List MCP servers'
      'add:Add MCP server'
      'remove:Remove MCP server'
      'enable:Enable MCP server'
      'disable:Disable MCP server'
    )
    _describe -t commands "mcp commands" mcp_cmds
    return
  fi
  
  local mcp_cmd=$words[3]
  
  case "$mcp_cmd" in
    add)
      _arguments \
        '--name[Server name]:name: ' \
        '--command[Command]:command:_command_names' \
        '--url[URL]:url: ' \
        '--env[Environment]:env: '
      ;;
    remove|enable|disable)
      # Would need to list configured MCP servers
      ;;
  esac
}

_gemini_extensions_completion() {
  if (( CURRENT == 3 )); then
    local ext_cmds=(
      'list:List extensions'
      'install:Install extension'
      'uninstall:Uninstall extension'
      'enable:Enable extension'
      'disable:Disable extension'
      'update:Update extensions'
    )
    _describe -t commands "extension commands" ext_cmds
    return
  fi
  
  local ext_cmd=$words[3]
  
  case "$ext_cmd" in
    uninstall|enable|disable)
      _gemini_extensions
      ;;
    install)
      _message 'Extension name or path'
      ;;
  esac
}

_gemini_skills_completion() {
  if (( CURRENT == 3 )); then
    local skill_cmds=(
      'list:List skills'
      'enable:Enable skill'
      'disable:Disable skill'
      'info:Show skill info'
    )
    _describe -t commands "skill commands" skill_cmds
    return
  fi
  
  local skill_cmd=$words[3]
  
  case "$skill_cmd" in
    enable|disable|info)
      _gemini_skills
      ;;
  esac
}

_gemini_prompt_suggestions() {
  local -a suggestions
  suggestions=(
    '"Explain this code"'
    '"Fix this bug"'
    '"Add error handling"'
    '"Write tests"'
    '"Refactor this"'
    '"Optimize performance"'
    '"Add documentation"'
    '"Convert to Python"'
    '"Review security"'
    '"Add logging"'
    '"Implement feature"'
    '"Add validation"'
  )
  
  _describe -t suggestions "prompt suggestions" suggestions
}

compdef _gemini gemini

# ============================================================
# ALIASES
# ============================================================

alias g='gemini'
alias gm='gemini'
alias gmi='gemini'

# Mode aliases
alias gyolo='gemini --yolo'
alias gplan='gemini --approval-mode plan'
alias gauto='gemini --approval-mode auto_edit'

# Model aliases
alias gpro='gemini --model gemini-2.5-pro'
alias gflash='gemini --model gemini-2.0-flash'
alias glite='gemini --model gemini-2.0-flash-lite'

# Quick action aliases
alias gfix='gemini -p "Fix this code"'
alias gtest='gemini -p "Write tests"'
alias gdoc='gemini -p "Add documentation"'
alias gexplain='gemini -p "Explain this"'
alias grefactor='gemini -p "Refactor this"'
alias greview='gemini -p "Review this"'

# Resume aliases
alias gresume='gemini --resume latest'
alias gr='gemini --resume'
