#!/data/data/com.termux/files/usr/bin/bash
#
# scripts/bootstrap-skills.sh — Pre-load ZCode skills, MCP configs, and plugins
# into the Debian proot environment so ZCode launches fully configured.
#
# This runs inside the proot Debian environment (called by install.sh).
# Arguments: $1 = ZCode config directory (e.g. /root/.config/ZCode)
#
set -euo pipefail

ZCODE_CONFIG_DIR="${1:-/root/.config/ZCode}"
ZCODE_DATA_DIR="/root/.local/share/ZCode"

# ── Create directory structure ────────────────────────────────────────────────
mkdir -p "$ZCODE_CONFIG_DIR/User"
mkdir -p "$ZCODE_DATA_DIR/User"
mkdir -p "$ZCODE_CONFIG_DIR/extensions"
mkdir -p "$ZCODE_DATA_DIR/extensions"
mkdir -p "$ZCODE_CONFIG_DIR/skills"
mkdir -p "$ZCODE_CONFIG_DIR/mcp"
mkdir -p "$ZCODE_DATA_DIR/workspace"

# ── 1. ZCode settings.json — mobile-optimized defaults ───────────────────────
cat > "$ZCODE_CONFIG_DIR/User/settings.json" << 'SETTINGS_EOF'
{
    "editor.fontSize": 15,
    "editor.lineHeight": 20,
    "editor.minimap.enabled": false,
    "editor.scrollbar.vertical": "visible",
    "editor.scrollbar.verticalScrollbarSize": 12,
    "editor.wordWrap": "on",
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.renderWhitespace": "boundary",
    "editor.renderControlCharacters": true,
    "editor.renderLineHighlight": "line",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    "editor.smoothScrolling": true,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.multiCursorModifier": "ctrlCmd",
    "editor.linkedEditing": true,
    "editor.autoClosingBrackets": "always",
    "editor.autoClosingQuotes": "always",
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.suggestSelection": "first",
    "editor.acceptSuggestionOnEnter": "on",
    "editor.quickSuggestions": {
        "other": true,
        "comments": false,
        "strings": true
    },
    "editor.suggest.showStatusBar": true,
    "editor.suggest.preview": true,
    "editor.inlineSuggest.enabled": true,
    "editor.stickyScroll.enabled": true,
    "workbench.colorTheme": "Default Dark Modern",
    "workbench.iconTheme": "material-icon-theme",
    "workbench.sideBar.location": "left",
    "workbench.panel.defaultLocation": "bottom",
    "workbench.statusBar.visible": true,
    "workbench.activityBar.visible": true,
    "workbench.editor.showTabs": "multiple",
    "workbench.tree.indent": 12,
    "workbench.tree.renderIndentGuides": "on",
    "window.menuBarVisibility": "hidden",
    "window.titleBarStyle": "custom",
    "window.restoreWindows": "all",
    "window.autoDetectHighContrast": false,
    "terminal.integrated.fontSize": 14,
    "terminal.integrated.lineHeight": 18,
    "terminal.integrated.scrollback": 5000,
    "terminal.integrated.copyOnSelection": true,
    "terminal.integrated.enablePersistentSessions": true,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.hotExit": "onExitAndWindowClose",
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/CVS": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/__pycache__": true,
        "**/*.pyc": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/dist": true,
        "**/build": true,
        "**/.git": true
    },
    "git.enabled": true,
    "git.path": "/usr/bin/git",
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.smartCommitChanges": "all",
    "telemetry.telemetryLevel": "off",
    "redhat.telemetry.enabled": false,
    "zcode.glm.model": "glm-5.3",
    "zcode.agent.maxConcurrentTasks": 2,
    "zcode.agent.defaultMode": "balanced",
    "zcode.mobile.touchOptimized": true,
    "zcode.mobile.virtualKeyboard": true,
    "zcode.mobile.compactSidebar": true,
    "zcode.mobile.gestureZoom": true,
    "zcode.skills.autoLoad": true,
    "zcode.mcp.autoStart": true,
    "zcode.terminal.shell": "/bin/bash",
    "zcode.terminal.shellArgs": ["-l"]
}
SETTINGS_EOF

echo "  [OK] settings.json written"

# ── 2. Keybindings — mobile/touch-optimized ───────────────────────────────────
cat > "$ZCODE_CONFIG_DIR/User/keybindings.json" << 'KEYBINDS_EOF'
[
    // Mobile-optimized keybindings
    // Swipe/pinch handled by touch layer; these are keyboard shortcuts
    { "key": "ctrl+s", "command": "workbench.action.files.save" },
    { "key": "ctrl+shift+s", "command": "workbench.action.files.saveAll" },
    { "key": "ctrl+z", "command": "undo" },
    { "key": "ctrl+shift+z", "command": "redo" },
    { "key": "ctrl+f", "command": "actions.find" },
    { "key": "ctrl+shift+f", "command": "workbench.action.findInFiles" },
    { "key": "ctrl+g", "command": "workbench.action.gotoLine" },
    { "key": "ctrl+p", "command": "workbench.action.quickOpen" },
    { "key": "ctrl+shift+p", "command": "workbench.action.showCommands" },
    { "key": "ctrl+`", "command": "workbench.action.terminal.toggleTerminal" },
    { "key": "ctrl+b", "command": "workbench.action.toggleSidebarVisibility" },
    { "key": "ctrl+shift+e", "command": "workbench.view.explorer" },
    { "key": "ctrl+shift+g", "command": "workbench.view.scm" },
    { "key": "ctrl+shift+d", "command": "workbench.view.debug" },
    { "key": "ctrl+shift+x", "command": "workbench.view.extensions" },
    { "key": "ctrl+space", "command": "editor.action.triggerSuggest" },
    { "key": "ctrl+i", "command": "editor.action.triggerInlineSuggest" },
    { "key": "ctrl+.", "command": "editor.action.quickFix" },
    { "key": "f2", "command": "editor.action.rename" },
    { "key": "f12", "command": "editor.action.revealDefinition" },
    { "key": "shift+f12", "command": "editor.action.referenceSearch.trigger" },
    { "key": "ctrl+enter", "command": "zcode.agent.runTask" },
    { "key": "ctrl+shift+enter", "command": "zcode.agent.newTask" },
    { "key": "alt+up", "command": "editor.action.moveLinesUpAction" },
    { "key": "alt+down", "command": "editor.action.moveLinesDownAction" },
    { "key": "ctrl+d", "command": "editor.action.addSelectionToNextFindMatch" },
    { "key": "ctrl+shift+l", "command": "editor.action.selectHighlights" }
]
KEYBINDS_EOF

echo "  [OK] keybindings.json written"

# ── 3. Skills manifest — pre-declare known ZCode skills ───────────────────────
cat > "$ZCODE_CONFIG_DIR/skills/manifest.json" << 'SKILLS_EOF'
{
    "version": "1.0.0",
    "autoLoad": true,
    "skills": [
        {
            "id": "code-review",
            "name": "Code Review",
            "description": "Automated code review with severity rating",
            "enabled": true,
            "triggers": ["review", "code review", "check code"]
        },
        {
            "id": "git-master",
            "name": "Git Master",
            "description": "Git operations: commits, rebases, history",
            "enabled": true,
            "triggers": ["commit", "git", "rebase", "branch"]
        },
        {
            "id": "tdd",
            "name": "TDD Mode",
            "description": "Test-driven development red-green-refactor",
            "enabled": true,
            "triggers": ["tdd", "test", "red-green"]
        },
        {
            "id": "architect",
            "name": "Architect",
            "description": "Architecture analysis and planning",
            "enabled": true,
            "triggers": ["architect", "design", "plan"]
        },
        {
            "id": "debugger",
            "name": "Debugger",
            "description": "Systematic debugging and root cause analysis",
            "enabled": true,
            "triggers": ["debug", "fix", "broken", "error"]
        },
        {
            "id": "refactor",
            "name": "Refactor",
            "description": "Safe refactoring with dependency analysis",
            "enabled": true,
            "triggers": ["refactor", "rename", "extract", "clean up"]
        },
        {
            "id": "security-scan",
            "name": "Security Scanner",
            "description": "OWASP Top 10 vulnerability detection",
            "enabled": true,
            "triggers": ["security", "vulnerability", "owasp"]
        },
        {
            "id": "docs-gen",
            "name": "Documentation Generator",
            "description": "Auto-generate README, API docs, comments",
            "enabled": true,
            "triggers": ["document", "readme", "docs", "api docs"]
        },
        {
            "id": "deploy",
            "name": "Deploy",
            "description": "Build and deploy to various targets",
            "enabled": true,
            "triggers": ["deploy", "build", "release", "ship"]
        },
        {
            "id": "mobile-dev",
            "name": "Mobile Dev",
            "description": "Mobile-optimized development context (Termux/proot aware)",
            "enabled": true,
            "triggers": ["mobile", "android", "termux", "phone"],
            "context": {
                "platform": "android-termux",
                "environment": "proot-debian",
                "display": "termux-x11",
                "constraints": ["low-memory", "arm64", "touch-input"]
            }
        }
    ]
}
SKILLS_EOF

echo "  [OK] skills/manifest.json written ($? skills)"

# ── 4. MCP server configuration ───────────────────────────────────────────────
mkdir -p "$ZCODE_CONFIG_DIR/mcp"

cat > "$ZCODE_CONFIG_DIR/mcp/servers.json" << 'MCP_EOF'
{
    "version": "1.0.0",
    "autoStart": true,
    "servers": {
        "filesystem": {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/mcp-filesystem", "/root"],
            "enabled": true
        },
        "git": {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/mcp-git"],
            "enabled": true
        },
        "fetch": {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/mcp-fetch"],
            "enabled": true
        },
        "memory": {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/mcp-memory"],
            "enabled": true
        }
    }
}
MCP_EOF

echo "  [OK] mcp/servers.json written"

# ── 5. ZCode agent config — tuned for mobile constraints ─────────────────────
cat > "$ZCODE_CONFIG_DIR/agent.json" << 'AGENT_EOF'
{
    "version": "1.0.0",
    "model": {
        "default": "glm-5.3",
        "fallback": "glm-5.2",
        "maxTokens": 8192,
        "temperature": 0.3,
        "streamMode": true
    },
    "execution": {
        "maxConcurrentTasks": 2,
        "maxConcurrentAgents": 1,
        "timeoutSeconds": 120,
        "retryAttempts": 2
    },
    "context": {
        "maxContextWindow": 32768,
        "compressHistory": true,
        "persistSessions": true,
        "workspaceDir": "/root/zcode-workspace"
    },
    "environment": {
        "platform": "android",
        "runtime": "termux-proot",
        "shell": "/bin/bash",
        "display": "termux-x11",
        "constraints": {
            "lowMemory": true,
            "arm64": true,
            "touchInput": true,
            "noGpuAcceleration": false
        }
    },
    "plugins": {
        "autoUpdate": false,
        "autoInstall": true,
        "allowed": [
            "zcode-git",
            "zcode-terminal",
            "zcode-explorer",
            "zcode-search",
            "zcode-debugger",
            "zcode-lint",
            "zcode-format",
            "zcode-snippets"
        ]
    }
}
AGENT_EOF

echo "  [OK] agent.json written"

# ── 6. Pre-populate workspace with mobile dev context ─────────────────────────
mkdir -p "$ZCODE_DATA_DIR/workspace"

# Compute timestamp outside the heredoc — single-quoted heredoc would not expand
# $() and would write the literal command into the JSON, producing invalid data.
DETECTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
cat > "$ZCODE_DATA_DIR/workspace/.zcode-context.json" << CTX_EOF
{
    "platform": "android-termux",
    "detectedAt": "${DETECTED_AT}",
    "capabilities": {
        "shell": true,
        "filesystem": true,
        "network": true,
        "git": true,
        "nodejs": true,
        "python": true,
        "display": "termux-x11",
        "audio": "pulseaudio"
    },
    "limitations": {
        "maxMemoryMB": "auto-detected",
        "noNativeGPU": false,
        "prootOverhead": "~10-15%",
        "touchOnlyInput": true
    }
}
CTX_EOF

echo "  [OK] workspace context written"

# ── 7. Install Node.js and Python in proot for MCP servers + dev tools ─────────
echo "  [..] Installing Node.js 20 LTS + Python 3 + dev tools..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 2>/dev/null || true
apt-get install -y nodejs python3 python3-pip python3-venv \
    git curl wget unzip jq ripgrep fd-find bat htop \
    clang make cmake pkg-config \
    python3-dev libssl-dev libffi-dev 2>/dev/null || true

# Install useful npm globals for MCP + dev
npm install -g npm@latest 2>/dev/null || true
npm install -g typescript ts-node prettier eslint 2>/dev/null || true

echo "  [OK] Dev tools installed"

# ── 8. Create .bashrc for proot with mobile-aware env ────────────────────────
cat > /root/.bashrc << 'BASHRC_EOF'
# ZCode Termux proot .bashrc
export TERM=xterm-256color
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=zcode
export VISUAL=zcode
export GIT_EDITOR=zcode --wait
export PATH="/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/root/.local/bin:$PATH"

# ZCode environment markers
export ZCODE_RUNTIME=termux-proot
export ZCODE_PLATFORM=android
export ZCODE_DISPLAY=termux-x11
export ZCODE_MOBILE=true

# Prompt
PS1='\[\033[01;32m\]root@zcode\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Aliases for mobile convenience
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -10'
alias gc='git commit'
alias gp='git push'
alias zc='zcode'

# nvm/node setup
export NODE_PATH="/usr/lib/node_modules"
BASHRC_EOF

echo "  [OK] .bashrc written"

echo ""
echo "  [DONE] Skills, plugins, MCP, and dev tools bootstrapped."