#!/bin/bash
# =============================================================================
# install.sh — structure-projects 规则安装脚本
# 用于将规则集安装到目标业务项目（项目级安装，非全局安装）
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET=""
STACKS=""
TOOLS=""
INSTALL_COMMON=false
INTERACTIVE=false
LIST_MODE=false
DRY_RUN=false

# ====== 颜色 ======
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() { printf "%b%s%b\n" "$1" "$2" "$NC"; }
info()    { print_color "$BLUE" "[INFO] $1"; }
success() { print_color "$GREEN" "[OK] $1"; }
warn()    { print_color "$YELLOW" "[WARN] $1"; }
error()   { print_color "$RED" "[ERROR] $1"; exit 1; }

# ====== 扫描可用技术栈 ======
find_stack_path() {
  local name="$1"
  # search architecture: backend/java/, frontend/, cross-platform/mobile/, etc.
  while IFS= read -r -d '' dir; do
    local dir_name
    dir_name=$(basename "$dir")
    if [[ "$dir_name" == "$name" ]]; then
      echo "$dir"
      return 0
    fi
  done < <(find "$SCRIPT_DIR" -mindepth 1 -maxdepth 4 -type d -name "$name" \
            -not -path "*/.git/*" -not -path "*/.claude/*" -not -path "*/.cursor/*" \
            -not -path "*/prompts/*" -not -path "*/codex/*" \
            -not -path "*/.trae/*" -not -path "*/.codebuddy/*" -not -path "*/.lingma/*" \
            -not -path "*/_common/*" -print0)
  return 1
}

list_all_stacks() {
  echo ""
  echo "==================== 可用技术栈 ===================="
  echo ""
  echo "--- 后端 ---"
  echo ""
  for category in backend/*/; do
    local lang
    lang=$(basename "$category")
    for stack in "$category"*/; do
      local name
      name=$(basename "$stack")
      if [ -f "$stack/AGENTS.md" ]; then
        echo "  [内容] $lang/$name"
      else
        echo "  [占位] $lang/$name"
      fi
    done
  done
  echo ""
  echo "--- 前端 ---"
  for stack in frontend/*/; do
    local name
    name=$(basename "$stack")
    if [ -f "$stack/AGENTS.md" ]; then
      echo "  [内容] $name"
    else
      echo "  [占位] $name"
    fi
  done
  echo ""
  echo "--- 跨平台 ---"
  for domain in cross-platform/*/; do
    local dom
    dom=$(basename "$domain")
    for stack in "$domain"*/; do
      local name
      name=$(basename "$stack")
      echo "  [占位] $dom/$name"
    done
  done
  echo ""
  echo "通用规则: _common/"
  echo ""
  echo "安装示例:"
  echo "  ./install.sh -t ../my-erp -s structure-boot,vue3 -w cursor,codebuddy"
  echo "  ./install.sh -t ../my-app -s structure-boot -w all -c"
  echo "  ./install.sh -i  (交互模式)"
  echo "===================================================="
  echo ""
}

# ====== 安装通用规则 ======
install_common() {
  if [ ! -d "$SCRIPT_DIR/_common" ]; then
    warn "通用规则目录 _common/ 不存在，跳过"
    return
  fi

  local common_dest="$TARGET/.structure-rules/prompts/_common"
  mkdir -p "$common_dest"

  local copied=0
  for f in "$SCRIPT_DIR"/_common/*.md; do
    if [ -f "$f" ]; then
      cp "$f" "$common_dest/"
      copied=$((copied + 1))
    fi
  done

  if [ "$copied" -gt 0 ]; then
    success "_common → $TARGET/.structure-rules/prompts/_common/ ($copied files)"
  fi
}

# ====== 安装单个规则栈 ======
install_stack() {
  local name="$1"
  local stack_path
  stack_path=$(find_stack_path "$name") || {
    error "找不到技术栈 '$name'，请用 --list 查看可用列表"
  }

  local prompt_src="$stack_path/prompts"
  local prompt_dest="$TARGET/.structure-rules/prompts/$name"

  # 1. 拷贝 prompts/
  if [ -d "$prompt_src" ]; then
    mkdir -p "$prompt_dest"
    cp "$prompt_src"/*.md "$prompt_dest/" 2>/dev/null || true
    local pcount
    pcount=$(find "$prompt_dest" -name "*.md" | wc -l | tr -d ' ')
    success "$name → .structure-rules/prompts/$name/ ($pcount prompts)"
  else
    warn "$name 无 prompts/ 目录，跳过"
  fi

  # 2. 拷贝 IDE 包装文件
  for tool in ${TOOLS//,/ }; do
    case "$tool" in
      all)
        for t in claude cursor trae codebuddy lingma; do
          install_tool_wrappers "$name" "$stack_path" "$t"
        done
        break
        ;;
      claude|cursor|trae|codebuddy|lingma)
        install_tool_wrappers "$name" "$stack_path" "$tool"
        ;;
      *)
        warn "未知工具 '$tool'，跳过"
        ;;
    esac
  done
}

install_tool_wrappers() {
  local name="$1" stack_path="$2" tool="$3"
  local src_dir dest_dir ext

  case "$tool" in
    claude)
      src_dir="$stack_path/.claude/agents"
      dest_dir="$TARGET/.claude/agents"
      ext="md"
      ;;
    cursor)
      src_dir="$stack_path/.cursor/rules"
      dest_dir="$TARGET/.cursor/rules"
      ext="mdc"
      ;;
    trae)
      src_dir="$stack_path/.trae/rules"
      dest_dir="$TARGET/.trae/rules"
      ext="md"
      ;;
    codebuddy)
      src_dir="$stack_path/.codebuddy/rules"
      dest_dir="$TARGET/.codebuddy/rules"
      ext="md"
      ;;
    lingma)
      src_dir="$stack_path/.lingma/rules"
      dest_dir="$TARGET/.lingma/rules"
      ext="md"
      ;;
    *) return ;;
  esac

  if [ ! -d "$src_dir" ]; then
    return
  fi

  mkdir -p "$dest_dir"
  local count=0
  for f in "$src_dir"/*."$ext"; do
    if [ -f "$f" ]; then
      local fname fnewname
      fname=$(basename "$f")
      # 文件名已自带前缀如 vue3-developer.mdc，无需再加
      fnewname="${fname}"
      cp "$f" "$dest_dir/$fnewname"
      count=$((count + 1))
    fi
  done

  if [ "$count" -gt 0 ]; then
    success "$name → .${tool}/ ($count wrappers)"
  fi
}

# ====== 合并 Codex AGENTS.md ======
merge_codex() {
  local out="$TARGET/AGENTS.md"
  echo "# AGENTS.md — 全栈项目 AI 规则" > "$out"
  echo "" >> "$out"
  echo "> 由 structure-agent-rules install.sh 自动生成。" >> "$out"
  echo "> 安装的技术栈: ${STACKS}" >> "$out"
  echo "" >> "$out"

  for name in ${STACKS//,/ }; do
    local stack_path codex_src
    stack_path=$(find_stack_path "$name") || continue
    codex_src="$stack_path/codex/AGENTS.md"
    if [ -f "$codex_src" ]; then
      echo "## $name" >> "$out"
      echo "" >> "$out"
      cat "$codex_src" >> "$out"
      echo "" >> "$out"
    fi
  done

  success "AGENTS.md 已合并生成"
}

# ====== 参数解析 ======
usage() {
  echo ""
  echo "用法: install.sh [选项]"
  echo ""
  echo "选项:"
  echo "  -t, --target <路径>      目标项目路径（必需）"
  echo "  -s, --stacks <列表>      技术栈列表，逗号分隔"
  echo "  -w, --with <列表>        AI 工具，逗号分隔 (cursor,codebuddy,claude,trae,lingma,all)"
  echo "  -c, --common             安装通用规则 (命名/API/安全/架构/测试等 10 项)"
  echo "  --list                   列出所有可用技术栈"
  echo "  -i, --interactive        交互模式"
  echo "  --dry-run                仅展示将要执行的操作"
  echo "  -h, --help               显示帮助"
  echo ""
  echo "示例:"
  echo "  ./install.sh -t ../my-erp -s structure-boot,vue3 -w cursor,codebuddy"
  echo "  ./install.sh -t ../my-service -s structure-boot -w all -c"
  echo "  ./install.sh -i"
  echo ""
}

# ====== 交互模式 ======
interactive_mode() {
  echo ""
  echo "======================== setup-projects 规则安装 ========================"
  echo ""
  echo "本脚本将规则安装到目标项目的 .structure-rules/ 和对应 AI 工具目录。"
  echo ""

  # 目标路径
  read -r -p "目标项目路径（如 ../my-erp）: " TARGET
  TARGET="${TARGET/#~/$HOME}"
  if [ -z "$TARGET" ]; then
    error "目标路径不能为空"
  fi

  # 选择后端
  echo ""
  echo "选择后端技术栈（多选用逗号分隔，直接回车跳过）:"
  for category in backend/*/; do
    local lang
    lang=$(basename "$category")
    for stack in "$category"*/; do
      local name
      name=$(basename "$stack")
      if [ -f "$stack/AGENTS.md" ]; then
        echo "  $lang/$name [内容]"
      else
        echo "  $lang/$name [占位]"
      fi
    done
  done
  read -r -p "后端 (逗号分隔): " BE_STACKS

  # 选择前端
  echo ""
  echo "选择前端技术栈（多选用逗号分隔，直接回车跳过）:"
  for stack in frontend/*/; do
    local name
    name=$(basename "$stack")
    if [ -f "$stack/AGENTS.md" ]; then
      echo "  $name [内容]"
    else
      echo "  $name [占位]"
    fi
  done
  read -r -p "前端 (逗号分隔): " FE_STACKS

  # 合并
  if [ -n "$BE_STACKS" ] && [ -n "$FE_STACKS" ]; then
    STACKS="$BE_STACKS,$FE_STACKS"
  elif [ -n "$BE_STACKS" ]; then
    STACKS="$BE_STACKS"
  elif [ -n "$FE_STACKS" ]; then
    STACKS="$FE_STACKS"
  fi

  if [ -z "$STACKS" ]; then
    error "至少选择一个技术栈"
  fi

  # 选择工具
  echo ""
  echo "部署到哪些 AI 工具？"
  echo "  [1] cursor"
  echo "  [2] codebuddy"
  echo "  [3] claude"
  echo "  [4] trae"
  echo "  [5] lingma"
  echo "  [6] 全部"
  read -r -p "选择 (多选用逗号分隔, 如 1,2): " TOOL_CHOICES

  for choice in ${TOOL_CHOICES//,/ }; do
    case "$choice" in
      1) TOOLS="${TOOLS}cursor," ;;
      2) TOOLS="${TOOLS}codebuddy," ;;
      3) TOOLS="${TOOLS}claude," ;;
      4) TOOLS="${TOOLS}trae," ;;
      5) TOOLS="${TOOLS}lingma," ;;
      6) TOOLS="all"; break ;;
    esac
  done
  TOOLS="${TOOLS%,}"
  [ -z "$TOOLS" ] && error "至少选择一个工具"

  # 通用规则
  read -r -p "安装通用规则 (命名/API/安全/架构/测试等 10 项)? [y/N] " COMMON_CHOICE
  if [[ "$COMMON_CHOICE" =~ ^[Yy]$ ]]; then
    INSTALL_COMMON=true
  fi
}

# ====== 主流程 ======
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--target) TARGET="$2"; shift 2 ;;
      -s|--stacks) STACKS="$2"; shift 2 ;;
      -w|--with) TOOLS="$2"; shift 2 ;;
      -c|--common) INSTALL_COMMON=true; shift ;;
      --list) LIST_MODE=true; shift ;;
      -i|--interactive) INTERACTIVE=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) error "未知参数: $1" ;;
    esac
  done
}

main() {
  parse_args "$@"

  if [ "$LIST_MODE" = true ]; then
    list_all_stacks
    exit 0
  fi

  if [ "$INTERACTIVE" = true ]; then
    interactive_mode
  fi

  # 验证参数
  [ -z "$TARGET" ] && error "请指定目标项目路径 (-t / --target)"
  [ -z "$STACKS" ] && error "请指定技术栈 (-s / --stacks)"
  [ -z "$TOOLS" ] && error "请指定 AI 工具 (-w / --with)"

  # 转为绝对路径
  TARGET="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)/$(basename "$TARGET")" || {
    # 目标可能还不存在，尝试创建
    TARGET="$(cd "$SCRIPT_DIR" && cd "$TARGET" 2>/dev/null && pwd)" || {
      mkdir -p "$TARGET" 2>/dev/null || error "无法创建或访问目标路径 $TARGET"
      TARGET="$(cd "$TARGET" && pwd)"
    }
  }

  echo ""
  echo "==================== 安装摘要 ===================="
  echo "目标:   $TARGET"
  echo "规则栈: $STACKS"
  echo "工具:   $TOOLS"
  echo "通用:   $([ "$INSTALL_COMMON" = true ] && echo 'yes' || echo 'no')"
  echo "=================================================="
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "dry-run 模式，不实际执行"
    exit 0
  fi

  # 创建必要目录
  mkdir -p "$TARGET/.structure-rules/prompts"

  # 安装每个规则栈
  for name in ${STACKS//,/ }; do
    name="${name## }"
    name="${name%% }"
    install_stack "$name"
  done

  # 安装通用规则
  if [ "$INSTALL_COMMON" = true ]; then
    install_common
  fi

  # 合并 Codex
  merge_codex

  echo ""
  echo "==================== 安装完成 ===================="
  echo ""
  echo "📦 已安装到 $TARGET/"
  echo "   prompts: .structure-rules/prompts/"
  echo "   cursor:  .cursor/rules/"
  echo "   codebuddy:.codebuddy/rules/"
  echo "   claude:  .claude/agents/"
  echo "   trae:    .trae/rules/"
  echo "   lingma:  .lingma/rules/"
  echo "   codex:   AGENTS.md"
  echo ""
}

main "$@"
