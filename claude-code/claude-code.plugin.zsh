# Claude Code - Anthropic's AI CLI
# Comprehensive completions with dynamic context awareness

if (( ! $+commands[claude] )); then
  return
fi

# ============================================================
# CACHE AND STATE MANAGEMENT
# ============================================================

_claude_cache_dir="${ZSH_CACHE_DIR}/claude"
mkdir -p "$_claude_cache_dir"

# Get list of recent sessions
_claude_sessions() {
  local cache_file="$_claude_cache_dir/sessions"
  local fresh=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))
  
  if [[ ! -f "$cache_file" || $fresh -gt 60 ]]; then
    # Look for session files in ~/.claude/sessions or similar
    local session_dir="${HOME}/.claude/sessions"
    if [[ -d "$session_dir" ]]; then
      ls -t "$session_dir" 2>/dev/null | head -20 >| "$cache_file"
    fi
  fi
  
  [[ -f "$cache_file" ]] && cat "$cache_file"
}

# Get available agents from config
_claude_agents() {
  local agents=(
    'default:Default Claude agent'
    'code:Code-focused agent'
    'review:Code review agent'
    'debug:Debugging agent'
    'architect:System architecture agent'
  )
  
  # Add custom agents from config if exists
  local config_file="${HOME}/.claude/config.json"
  if [[ -f "$config_file" ]]; then
    local custom=$(cat "$config_file" | grep -o '"agents"[^}]*' | grep -o '"[a-zA-Z0-9_-]*"' | tr -d '"' 2>/dev/null)
    for agent in ${(f)custom}; do
      [[ -n "$agent" ]] && agents+=("$agent:Custom agent")
    done
  fi
  
  print -l "${agents[@]}"
}

# Get allowed tools list
_claude_tools() {
  local tools=(
    'Bash:Execute shell commands'
    'Edit:Edit files'
    'Read:Read file contents'
    'Write:Write files'
    'Grep:Search files'
    'Glob:File pattern matching'
    'LS:List directory contents'
    'View:View file contents'
    'WebFetch:Fetch web content'
    'WebSearch:Search the web'
  )
  print -l "${tools[@]}"
}

# Get beta features
_claude_betas() {
  local betas=(
    'token-efficient-tools:Reduce token usage'
    'prompt-caching:Cache prompts for reuse'
    'extended-thinking:Extended thinking mode'
  )
  print -l "${betas[@]}"
}

# ============================================================
# MAIN COMPLETION FUNCTION
# ============================================================

_claude() {
  local curcontext="$curcontext" state line
  typeset -A opt_args
  
  local cur=$words[CURRENT]
  local prev=$words[CURRENT-1]
  
  # Complete based on position and context
  if (( CURRENT == 2 )); then
    # First argument - could be options or a prompt
    if [[ "$cur" == -* ]]; then
      _claude_options
    else
      # Could be a prompt or we can suggest common starting prompts
      _claude_prompt_suggestions
    fi
    return
  fi
  
  # Complete based on previous option
  case "$prev" in
    --agent|-a)
      local -a agents
      agents=(${(f)"$(_claude_agents)"})
      _describe -t agents "agents" agents
      return
      ;;
    --agents)
      # JSON object - suggest template
      _message 'JSON object: {"name": {"description": "...", "prompt": "..."}}'
      return
      ;;
    --allowed-tools|--allowedTools|--disallowed-tools|--disallowedTools)
      local -a tools
      tools=(${(f)"$(_claude_tools)"})
      _describe -t tools "tools" tools
      return
      ;;
    --betas)
      local -a betas
      betas=(${(f)"$(_claude_betas)"})
      _describe -t betas "beta features" betas
      return
      ;;
    --fallback-model)
      local models=(
        'claude-3-5-sonnet-20241022:Claude 3.5 Sonnet'
        'claude-3-5-haiku-20241022:Claude 3.5 Haiku'
        'claude-3-opus-20240229:Claude 3 Opus'
      )
      _describe -t models "models" models
      return
      ;;
    --debug|-d)
      local debug_levels=(
        'api:API calls'
        'hooks:Hook execution'
        'statsig:Statsig events'
        'file:File operations'
        'all:All debug categories'
      )
      _describe -t debug "debug categories" debug_levels
      return
      ;;
    --debug-file)
      _files
      return
      ;;
    --file)
      _message 'Format: file_id:relative_path'
      return
      ;;
    --add-dir)
      _files -/
      return
      ;;
    --append-system-prompt|--system)
      # Suggest common system prompt additions
      local suggestions=(
        '"You are a helpful coding assistant"'
        '"Focus on code quality and best practices"'
        '"Be concise in your responses"'
        '"Always explain your reasoning"'
      )
      _describe -t suggestions "system prompt additions" suggestions
      return
      ;;
  esac
  
  # Complete options
  _claude_options
}

_claude_options() {
  local -a options
  options=(
    '(-c --continue)'{-c,--continue}'[Continue most recent conversation]'
    '(-r --resume)'{-r,--resume}'[Resume specific session]:session:_claude_sessions'
    '--fork-session[Create new session ID when resuming]'
    
    # Output modes
    '(-p --print)'{-p,--print}'[Non-interactive output mode]'
    '--output-format[Output format]:format:(text json markdown)'
    
    # Permissions and safety
    '--dangerously-skip-permissions[Bypass all permission checks]'
    '--allow-dangerously-skip-permissions[Allow bypass without default enable]'
    '--yolo[Automatically approve all actions]'
    
    # Tool configuration
    '--allowed-tools[Allowed tools]:tools:_claude_tools'
    '--disallowed-tools[Disallowed tools]:tools:_claude_tools'
    
    # Agent configuration
    '--agent[Agent for session]:agent:_claude_agents'
    '--agents[Custom agents JSON]:agents: '
    '--disable-slash-commands[Disable all skills]'
    
    # Model and API
    '--fallback-model[Fallback model]:model:(claude-3-5-sonnet-20241022 claude-3-5-haiku-20241022 claude-3-opus-20240229)'
    '--betas[Beta headers]:betas:_claude_betas'
    
    # Files and directories
    '--add-dir[Additional allowed directories]:directory:_files -/'
    '--file[File resources]:file spec: '
    
    # System and prompts
    '--append-system-prompt[Append to system prompt]:prompt: '
    '--system[System prompt override]:prompt: '
    
    # Debug and development
    '(-d --debug)'{-d,--debug}'[Enable debug mode]:filter:(api hooks statsig file all)'
    '--debug-file[Write debug logs]:file:_files'
    '--verbose[Verbose output]'
    
    # IDE integration
    '--ide[Auto-connect to IDE]'
    '--chrome[Enable Chrome integration]'
    
    # Help
    '(-h --help)'{-h,--help}'[Display help]'
    '--version[Show version]'
  )
  
  _describe -t options "claude options" options
}

_claude_prompt_suggestions() {
  local -a suggestions
  suggestions=(
    '"Review this code for bugs"'
    '"Explain how this function works"'
    '"Refactor this to use modern syntax"'
    '"Write tests for this module"'
    '"Optimize this for performance"'
    '"Add documentation to this code"'
    '"Convert this to TypeScript"'
    '"Help me debug this error"'
  )
  
  _describe -t suggestions "common prompts" suggestions
}

compdef _claude claude

# ============================================================
# ALIASES
# ============================================================

alias c='claude'
alias cc='claude --continue'
alias ccp='claude --continue --print'
alias cp='claude --print'
alias cyolo='claude --yolo'
alias ccoder='claude --agent code'
alias creview='claude --agent review'
alias cdebug='claude --agent debug'
alias carch='claude --agent architect'

# Quick command aliases
alias cfix='claude "Fix this code"'
alias cexplain='claude "Explain this code"'
alias ctest='claude "Write tests for this"'
alias cdoc='claude "Add documentation"'
alias crefactor='claude "Refactor this"'
alias coptimize='claude "Optimize this"'
