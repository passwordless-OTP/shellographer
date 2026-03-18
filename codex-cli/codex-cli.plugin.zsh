# Codex CLI - OpenAI's coding agent
# Comprehensive completions with context awareness

if (( ! $+commands[codex] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_codex_cache_dir="${ZSH_CACHE_DIR}/codex"
mkdir -p "$_codex_cache_dir"

# Get recent sessions
_codex_sessions() {
  local cache_file="$_codex_cache_dir/sessions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    # Check for sessions in ~/.codex or codex config
    codex resume --list 2>/dev/null | head -20 >| "$cache_file"
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get MCP servers
_codex_mcp_servers() {
  local cache_file="$_codex_cache_dir/mcp_servers"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 300 ]]; then
    codex mcp list 2>/dev/null | awk '{print $1}' >| "$cache_file"
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get available models
_codex_models() {
  local models=(
    'gpt-4o:GPT-4o (default)'
    'gpt-4o-mini:GPT-4o Mini'
    'o1:O1 reasoning model'
    'o1-mini:O1 Mini'
    'o3-mini:O3 Mini'
  )
  print -l "${models[@]}"
}

# Get approval modes
_codex_approval_modes() {
  local modes=(
    'suggest:Only suggest changes'
    'auto-edit:Auto-approve edits only'
    'full-auto:Auto-approve all actions'
  )
  print -l "${modes[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_codex() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # First level - commands or global options
  if (( CURRENT == 2 )); then
    if [[ "$cur" == -* ]]; then
      _codex_global_options
    else
      local commands=(
        'exec:Run non-interactively'
        'e:Alias for exec'
        'review:Run code review'
        'login:Manage login'
        'logout:Remove credentials'
        'mcp:Manage MCP servers'
        'mcp-server:Start as MCP server'
        'app-server:Run app server'
        'app:Launch desktop app'
        'completion:Generate shell completions'
        'sandbox:Run in sandbox'
        'debug:Debugging tools'
        'apply:Apply latest diff'
        'a:Alias for apply'
        'resume:Resume session'
        'fork:Fork session'
        'cloud:Browse Codex Cloud'
        'features:Inspect feature flags'
        'help:Show help'
      )
      _describe -t commands "codex commands" commands
    fi
    return
  fi
  
  local cmd=$words[2]
  
  # Complete based on subcommand
  case "$cmd" in
    exec|e)
      _codex_exec_completion
      ;;
    review)
      _codex_review_completion
      ;;
    mcp)
      _codex_mcp_completion
      ;;
    resume|fork)
      _arguments \
        '--last[Use most recent session]' \
        ':session:_codex_sessions'
      ;;
    cloud)
      _codex_cloud_completion
      ;;
    debug)
      _codex_debug_completion
      ;;
    apply|a)
      _arguments \
        '--dry-run[Show what would be applied]' \
        '--force[Force apply without confirmation]'
      ;;
    sandbox)
      _arguments \
        '(-c --command)'{-c,--command}'[Command to run]:command:_command_names' \
        '*::args:_files'
      ;;
    login|logout|completion|app|app-server|mcp-server|features|help)
      # No additional completions needed
      ;;
    *)
      # For interactive mode, complete options
      if [[ "$cur" == -* ]]; then
        _codex_global_options
      else
        _codex_prompt_suggestions
      fi
      ;;
  esac
}

_codex_global_options() {
  local -a options
  options=(
    # Model selection
    '--model[Model to use]:model:_codex_models'
    
    # Approval mode
    '--approval-mode[Approval mode]:mode:_codex_approval_modes'
    
    # Quiet mode
    '(-q --quiet)'{-q,--quiet}'[Non-interactive mode]'
    
    # Full auto mode (alias for --approval-mode full-auto)
    '(-y --yes)'{-y,--yes}'[Auto-approve all (YOLO mode)]'
    
    # Context
    '--context[Context files]:files:_files'
    '--image[Image files]:images:_files -g "*.{png,jpg,jpeg,gif,webp}"'
    
    # Workspace
    '-C[Change directory]:directory:_files -/'
    '--work-dir[Working directory]:directory:_files -/'
    
    # Config
    '--config[Config file]:file:_files'
    '--no-project-doc[Disable project doc]'
    '--project-doc[Project doc path]:file:_files'
    
    # Output
    '--output[Output file]:file:_files'
    '--format[Output format]:format:(text markdown json)'
    
    # Debug
    '--debug[Enable debug mode]'
    '-v[Verbose output]'
    
    # Help
    '(-h --help)'{-h,--help}'[Show help]'
    '--version[Show version]'
  )
  
  _describe -t options "codex options" options
}

_codex_exec_completion() {
  local -a options
  options=(
    # Input
    '(-p --prompt)'{-p,--prompt}'[Prompt to execute]:prompt: '
    '--file[File to process]:file:_files'
    '--stdin[Read from stdin]'
    
    # Output
    '--output[Output file]:file:_files'
    '--format[Output format]:format:(text markdown json diff)'
    
    # Behavior
    '--approval-mode[Approval mode]:mode:_codex_approval_modes'
    '--no-apply[Show diff without applying]'
    '--dry-run[Show what would be done]'
    
    # Context
    '--context[Additional context]:files:_files'
    '--include[Include patterns]:patterns: '
    '--exclude[Exclude patterns]:patterns: '
    
    # Help
    '(-h --help)'{-h,--help}'[Show help]'
  )
  
  _describe -t options "exec options" options
  
  # Suggest prompts if appropriate
  if [[ "$words[CURRENT]" != -* ]]; then
    _codex_prompt_suggestions
  fi
}

_codex_review_completion() {
  local -a options
  options=(
    # Scope
    '--files[Files to review]:files:_files'
    '--diff[Review diff only]'
    '--pr[Review PR]:pr number: '
    '--branch[Review branch]:branch: '
    '--commit[Review commit]:commit: '
    
    # Review type
    '--type[Review type]:type:(security performance readability maintainability all)'
    
    # Output
    '--output[Output file]:file:_files'
    '--format[Output format]:format:(text markdown json)'
    
    # Behavior
    '--approval-mode[Approval mode]:mode:_codex_approval_modes'
    
    # Help
    '(-h --help)'{-h,--help}'[Show help]'
  )
  
  _describe -t options "review options" options
}

_codex_mcp_completion() {
  if (( CURRENT == 3 )); then
    local mcp_cmds=(
      'list:List MCP servers'
      'add:Add MCP server'
      'remove:Remove MCP server'
      'enable:Enable MCP server'
      'disable:Disable MCP server'
      'config:Show MCP config'
    )
    _describe -t commands "mcp commands" mcp_cmds
    return
  fi
  
  local mcp_cmd=$words[3]
  
  case "$mcp_cmd" in
    remove|enable|disable)
      _codex_mcp_servers
      ;;
    add)
      _arguments \
        '--name[Server name]:name: ' \
        '--command[Command to run]:command:_command_names' \
        '--url[Server URL]:url: ' \
        '--env[Environment variables]:env: '
      ;;
  esac
}

_codex_cloud_completion() {
  if (( CURRENT == 3 )); then
    local cloud_cmds=(
      'list:List cloud tasks'
      'show:Show task details'
      'apply:Apply cloud task locally'
      'sync:Sync with cloud'
    )
    _describe -t commands "cloud commands" cloud_cmds
    return
  fi
  
  # Task ID completion would go here
}

_codex_debug_completion() {
  if (( CURRENT == 3 )); then
    local debug_cmds=(
      'logs:Show debug logs'
      'config:Show configuration'
      'status:Show system status'
      'test-connection:Test API connection'
    )
    _describe -t commands "debug commands" debug_cmds
    return
  fi
}

_codex_prompt_suggestions() {
  local -a suggestions
  suggestions=(
    '"Fix bugs in this code"'
    '"Add error handling"'
    '"Write unit tests"'
    '"Refactor for readability"'
    '"Optimize performance"'
    '"Add TypeScript types"'
    '"Document this API"'
    '"Review for security issues"'
    '"Modernize this code"'
    '"Add logging"'
    '"Implement missing features"'
    '"Add input validation"'
  )
  
  _describe -t suggestions "prompt suggestions" suggestions
}

compdef _codex codex

# ============================================================
# ALIASES
# ============================================================

alias cx='codex'
alias cxe='codex exec'
alias cxr='codex review'
alias cxl='codex resume --last'
alias cxm='codex mcp'
alias cxs='codex resume'

# Quick action aliases
alias cxfix='codex exec "Fix this code"'
alias cxtest='codex exec "Write tests"'
alias cxdoc='codex exec "Add documentation"'
alias cxreview='codex exec "Review this"'
alias cxrefactor='codex exec "Refactor this"'

# Mode aliases
alias cxyolo='codex --approval-mode full-auto'
alias cxsuggest='codex --approval-mode suggest'
alias cxedit='codex --approval-mode auto-edit'

# Model aliases
alias cx4o='codex --model gpt-4o'
alias cx4m='codex --model gpt-4o-mini'
alias cxo1='codex --model o1'
