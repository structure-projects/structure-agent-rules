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
# 栈目录只在 backend/ frontend/ cross-platform/ 三类根目录下，避免误匹配其他目录
STACK_ROOTS=(backend frontend cross-platform)

find_stack_path() {
  local name="$1"
  # 兼容用户输入 "java/structure-boot" 格式，提取实际的栈目录名
  local search_name="$name"
  if [[ "$name" == */* ]]; then
    search_name="${name##*/}"
  fi
  local matches=()
  local root
  for root in "${STACK_ROOTS[@]}"; do
    [ -d "$SCRIPT_DIR/$root" ] || continue
    while IFS= read -r -d '' dir; do
      matches+=("$dir")
    done < <(find "$SCRIPT_DIR/$root" -mindepth 1 -maxdepth 3 -type d -name "$search_name" -print0)
  done

  if [ "${#matches[@]}" -eq 0 ]; then
    return 1
  fi

  if [ "${#matches[@]}" -gt 1 ]; then
    warn "栈名 '$search_name' 匹配到 ${#matches[@]} 个目录，将使用第一个:"
    for m in "${matches[@]}"; do
      local rel="${m#$SCRIPT_DIR/}"
      echo "    $rel" >&2
    done
  fi

  echo "${matches[0]}"
  return 0
}

list_all_stacks() {
  echo ""
  echo "==================== 可用技术栈 ===================="
  echo ""
  echo "--- 后端 ---"
  echo ""
  for category in "$SCRIPT_DIR"/backend/*/; do
    [ -d "$category" ] || continue
    local lang
    lang=$(basename "$category")
    for stack in "$category"*/; do
      [ -d "$stack" ] || continue
      local name
      name=$(basename "$stack")
      if [ -f "$stack/prompts/developer.md" ]; then
        echo "  [内容] $lang/$name"
      else
        echo "  [占位] $lang/$name"
      fi
    done
  done
  echo ""
  echo "--- 前端 ---"
  for stack in "$SCRIPT_DIR"/frontend/*/; do
    [ -d "$stack" ] || continue
    local name
    name=$(basename "$stack")
    if [ -f "$stack/prompts/developer.md" ]; then
      echo "  [内容] $name"
    else
      echo "  [占位] $name"
    fi
  done
  echo ""
  echo "--- 跨平台 ---"
  for domain in "$SCRIPT_DIR"/cross-platform/*/; do
    [ -d "$domain" ] || continue
    local dom
    dom=$(basename "$domain")
    for stack in "$domain"*/; do
      [ -d "$stack" ] || continue
      local name
      name=$(basename "$stack")
      if [ -f "$stack/prompts/developer.md" ]; then
        echo "  [内容] $dom/$name"
      else
        echo "  [占位] $dom/$name"
      fi
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

  local common_dest="$TARGET/prompts/_common"
  mkdir -p "$common_dest"

  local copied=0
  COMMON_FILES=""
  for f in "$SCRIPT_DIR"/_common/*.md; do
    if [ -f "$f" ]; then
      cp "$f" "$common_dest/"
      COMMON_FILES="${COMMON_FILES}${common_dest}/$(basename "$f") "
      copied=$((copied + 1))
    fi
  done

  if [ "$copied" -gt 0 ]; then
    success "_common → prompts/_common/ ($copied files)"
    _build_common_ref
  fi
}

# ====== 安装单个规则栈 ======
install_stack() {
  local name="$1"
  local stack_path
  stack_path=$(find_stack_path "$name") || {
    error "找不到技术栈 '$name'，请用 --list 查看可用列表"
  }
  # 规范化为纯栈名（去掉可能存在的 lang/ 前缀）
  local canonical_name
  canonical_name=$(basename "$stack_path")

  local prompt_src="$stack_path/prompts"
  local prompt_dest="$TARGET/prompts/$canonical_name"

  # 1. 拷贝 prompts/（目录为空则不创建目标、不谎报成功）
  if [ -d "$prompt_src" ]; then
    local md_files=("$prompt_src"/*.md)
    if [ -e "${md_files[0]}" ]; then
      mkdir -p "$prompt_dest"
      cp "${md_files[@]}" "$prompt_dest/"
      success "$canonical_name → prompts/$canonical_name/ (${#md_files[@]} prompts)"
    else
      warn "$canonical_name 的 prompts/ 无 .md 文件，跳过"
    fi
  else
    warn "$canonical_name 无 prompts/ 目录，跳过"
  fi

  # 2. 拷贝 IDE 包装文件
  for tool in ${TOOLS//,/ }; do
    case "$tool" in
      all)
        for t in claude cursor trae codebuddy lingma codex; do
          [ "$t" = "codex" ] && continue
          install_tool_wrappers "$canonical_name" "$stack_path" "$t"
        done
        break
        ;;
      codex) ;;  # AGENTS.md 由 merge_codex 单独处理
      claude|cursor|trae|codebuddy|lingma)
        install_tool_wrappers "$canonical_name" "$stack_path" "$tool"
        ;;
      *)
        warn "未知工具 '$tool'，跳过"
        ;;
    esac
  done
}

# ====== 从 rules/*.mdc 转换为其他 AI 工具格式 ======
# 所有工具规则统一以 rules/*.mdc 为单一模板源，
# 安装时按以下规则自动派生：
#   Cursor:    直接拷贝 .mdc（保留 frontmatter）
#   CodeBuddy: 改 frontmatter（去 globs，保留 alwaysApply+description）
#   Claude:    改 frontmatter（name+description+tools），加 Agent 身份声明
#   Trae:      去掉 frontmatter，正文不变
#   Lingma:    去掉 frontmatter，正文不变

# 角色名 -> 中文标签
_role_label() {
  case "$1" in
    developer)    echo "开发" ;;
    architect)    echo "架构" ;;
    reviewer)     echo "评审" ;;
    tester)       echo "测试" ;;
    ci-cd)        echo "CI/CD" ;;
    components)   echo "组件" ;;
    project-scaffolding) echo "项目脚手架" ;;
    swagger)      echo "API 文档" ;;
    validation)   echo "数据校验" ;;
    *)            echo "$1" ;;
  esac
}

# 从 markdown 文件提取第一个 H1 标题
_get_title() {
  local file="$1"
  sed -n 's/^# //p;q' "$file" 2>/dev/null || basename "$file" .md
}

# 从 mdc 文件名提取角色名。多段角色（ci-cd / project-scaffolding）必须整体匹配，
# 不能用 ${fname##*-} 只取最后一段（会把 vue3-ci-cd 截成 cd）。
KNOWN_ROLES=(project-scaffolding components validation developer architect reviewer tester ci-cd swagger)

_extract_role() {
  local fname="$1"
  local r
  for r in "${KNOWN_ROLES[@]}"; do
    if [[ "$fname" == *"-$r" ]]; then
      echo "$r"
      return 0
    fi
  done
  # 未知角色按原样返回（调用方负责处理）
  echo "$fname"
}

# 根据已安装的 COMMON_FILES 构建引用段落文本，存入 COMMON_REF_TEXT
_build_common_ref() {
  if [ -z "${COMMON_FILES:-}" ]; then
    COMMON_REF_TEXT=""
    return
  fi
  local ref=""
  ref="> **通用规范** (已安装于 \`prompts/_common/\`):"
  ref="${ref}"$'\n'
  local f fname title
  for f in ${COMMON_FILES}; do
    fname=$(basename "$f")
    title=$(_get_title "$f")
    ref="${ref}> - \`prompts/_common/${fname}\`: ${title}"
    ref="${ref}"$'\n'
  done
  ref="${ref}> "$'\n'"> 在编码决策前应加载对应规范文件。"
  COMMON_REF_TEXT="$ref"
}

convert_mdc() {
  local src="$1" out="$2" tool="$3" stack_name="$4"

  local fname role desc always body
  fname=$(basename "$src" .mdc)
  role=$(_extract_role "$fname")

  # 提取 frontmatter 字段
  desc=$(awk '/^---$/ {c++; next} c==1 && /^description:/ {sub(/^description:[[:space:]]*/,""); print; exit}' "$src")
  always=$(awk '/^---$/ {c++; next} c==1 && /^alwaysApply:/ {sub(/^alwaysApply:[[:space:]]*/,""); print; exit}' "$src")
  always="${always:-false}"

  # 提取正文（第二个 --- 之后的所有内容），并把模板里的 prompts/X.md 重写为
  # 安装后的实际路径 prompts/<stack>/X.md（业务项目根目录视角）
  body=$(awk 'BEGIN{c=0} /^---$/ {c++; next} c>=2' "$src" \
    | sed -E "s|prompts/([a-z][a-z-]*\.md)|prompts/${stack_name}/\1|g")

  # 如果安装了 _common，在 wrapper body 头部注入引用段落
  local common_ref=""
  if [ -n "${COMMON_REF_TEXT:-}" ]; then
    common_ref="${COMMON_REF_TEXT}"$'\n\n'
  fi

  case "$tool" in
    codebuddy)
      {
        echo "---"
        echo "alwaysApply: $always"
        echo "description: $desc"
        echo "---"
        echo ""
        [ -n "$common_ref" ] && echo "$common_ref"
        echo "$body"
      } > "$out"
      ;;
    claude)
      local role_cn
      role_cn=$(_role_label "$role")
      {
        echo "---"
        echo "name: ${stack_name}-${role}"
        echo "description: $desc"
        echo "tools: Read, Write, Edit, Grep, Glob, Bash"
        echo "---"
        echo ""
        echo "你是 ${stack_name} 生态的${role_cn} Agent。"
        echo ""
        [ -n "$common_ref" ] && echo "$common_ref"
        echo "**首要动作**：在开始写代码前，先用 Read 加载 \`prompts/${stack_name}/${role}.md\`；涉及具体组件用法时再读 \`prompts/${stack_name}/components.md\`；新建项目时读 \`prompts/${stack_name}/project-scaffolding.md\`。以下为操作要点："
        echo ""
        echo "$body"
        echo ""
        echo "完整规则以 \`prompts/${stack_name}/${role}.md\` 为准。"
      } > "$out"
      ;;
    trae|lingma)
      # 直接输出正文，不带 frontmatter
      {
        [ -n "$common_ref" ] && echo "$common_ref"
        echo "$body"
      } > "$out"
      ;;
  esac
}

install_tool_wrappers() {
  local name="$1" stack_path="$2" tool="$3"
  local cursor_src="$stack_path/rules"
  local dest_dir ext

  case "$tool" in
    cursor)
      dest_dir="$TARGET/.cursor/rules"
      ext="mdc"
      ;;
    claude)
      dest_dir="$TARGET/.claude/agents"
      ext="md"
      ;;
    codebuddy)
      dest_dir="$TARGET/.codebuddy/rules"
      ext="md"
      ;;
    trae)
      dest_dir="$TARGET/.trae/rules"
      ext="md"
      ;;
    lingma)
      dest_dir="$TARGET/.lingma/rules"
      ext="md"
      ;;
    *) return ;;
  esac

  # 所有工具统一从 rules/*.mdc 读取源文件
  if [ ! -d "$cursor_src" ]; then
    return
  fi

  mkdir -p "$dest_dir"
  local count=0
  for f in "$cursor_src"/*.mdc; do
    [ -f "$f" ] || continue
    local fname fout
    fname=$(basename "$f")
    fout="$dest_dir/${fname%.mdc}.${ext}"

    # 同名文件覆盖保护：如果已存在且来自不同栈则警告
    if [ -f "$fout" ]; then
      warn "目标已存在 $fout，将被覆盖"
    fi

    if [ "$tool" = "cursor" ]; then
      # Cursor: 直接拷贝 .mdc，改名（保留 .mdc 扩展名）
      # 若安装了 _common，在 frontmatter 闭合后（第二个 --- 之后）注入引用段落
      if [ -n "${COMMON_REF_TEXT:-}" ]; then
        {
          local fc=0
          while IFS= read -r line || [ -n "$line" ]; do
            printf '%s\n' "$line"
            if [[ "$line" == "---" ]]; then
              fc=$((fc + 1))
              if [ $fc -eq 2 ]; then
                printf '\n%s\n\n' "$COMMON_REF_TEXT"
              fi
            fi
          done < "$f"
        } > "$fout"
      else
        cp "$f" "$fout"
      fi
    else
      # 其他工具: 从 .mdc 转换
      convert_mdc "$f" "$fout" "$tool" "$name"
    fi
    count=$((count + 1))
  done

  if [ "$count" -gt 0 ]; then
    local rel_dir="${dest_dir#$TARGET/}"
    success "$name → $rel_dir/ ($count wrappers)"
  fi
}

# ====== 安装前验证 ======
# 检查：1) 栈是否存在 2) 同名栈歧义 3) 输出文件名全局唯一性
validate_stacks() {
  local resolved_names=""        # "cname|spath" 列表
  local all_output_files=""      # "cname|basename" 列表，每项用换行分隔
  local issues=0

  for name in ${STACKS//,/ }; do
    name="${name## }"
    name="${name%% }"
    [ -z "$name" ] && continue

    local spath
    spath=$(find_stack_path "$name") || {
      error "找不到技术栈 '$name'，请用 --list 查看可用列表"
    }

    local cname
    cname=$(basename "$spath")

    # 检查同名栈歧义：用 grep 在 resolved_names 中查找是否已有同名
    local prev_path
    prev_path=$(echo "$resolved_names" | { grep "^${cname}|" || true; } | head -1 | cut -d'|' -f2-)
    if [ -n "$prev_path" ] && [ "$prev_path" != "$spath" ]; then
      warn "技术栈 '$name' 和之前选择的技术栈解析到相同的规范名 '$cname'"
      warn "  路径1: $prev_path"
      warn "  路径2: $spath"
      warn "  将只安装第一个匹配的栈，建议用完整路径指定 (如 java/spring-boot)"
      issues=$((issues + 1))
    else
      resolved_names="${resolved_names}${cname}|${spath}
"
    fi

    # 收集该栈的输出文件名
    local rules_dir="$spath/rules"
    if [ -d "$rules_dir" ]; then
      for f in "$rules_dir"/*.mdc; do
        [ -f "$f" ] || continue
        local base
        base=$(basename "$f" .mdc)
        all_output_files="${all_output_files}${cname}|${base}
"
      done
    fi
  done

  # 检查全局输出文件名冲突
  local prev_fname=""
  local prev_sname=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local sname="${line%%|*}"
    local fname="${line#*|}"
    if [ "$fname" = "$prev_fname" ] && [ "$sname" != "$prev_sname" ]; then
      error "输出文件名冲突: '$fname' 同时存在于 '$prev_sname' 和 '$sname' — 安装到扁平目录 (.cursor/rules/ 等) 会互相覆盖"
    fi
    prev_fname="$fname"
    prev_sname="$sname"
  done < <(echo "$all_output_files" | sort)

  if [ "$issues" -gt 0 ]; then
    info "共检测到 $issues 个警告，安装将继续"
  fi
  return 0
}
merge_codex() {
  # 只在用户选了 codex 或 all 时才生成
  local wants_codex=false
  local t
  for t in ${TOOLS//,/ }; do
    case "$t" in codex|all) wants_codex=true; break ;; esac
  done
  if [ "$wants_codex" != true ]; then
    info "未选择 codex，跳过 AGENTS.md 生成"
    return
  fi

  local out="$TARGET/AGENTS.md"

  # 覆盖保护：目标已存在 AGENTS.md 时备份并警告
  if [ -f "$out" ]; then
    local bak="${out}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$out" "$bak"
    warn "目标已存在 AGENTS.md，已备份到 ${bak##*/}"
  fi

  # 单 H1 头部
  {
    echo "# AGENTS.md — 全栈项目 AI 规则"
    echo ""
    echo "> 由 structure-agent-rules install.sh 自动生成。"
    echo "> 安装的技术栈: ${STACKS}"
    echo ""
  } > "$out"

  for name in ${STACKS//,/ }; do
    name="${name## }"; name="${name%% }"
    [ -z "$name" ] && continue
    local stack_path codex_src canonical_name
    stack_path=$(find_stack_path "$name") || continue
    canonical_name=$(basename "$stack_path")
    codex_src="$stack_path/codex/AGENTS.md"
    if [ -f "$codex_src" ]; then
      # 读取 codex 内容：跳过第一行 H1，其余输出，同时修正 prompts/ 路径
      {
        echo "## $canonical_name"
        echo ""
        tail -n +2 "$codex_src" \
          | sed -E "s|prompts/([a-z][a-z-]*\.md)|prompts/${canonical_name}/\1|g"
        echo ""
      } >> "$out"
    fi
  done

  # 如果安装了 _common，追加清单章节（仅文件名 + 路径指向，不 cat 全内容）
  if [ -n "${COMMON_FILES:-}" ]; then
    {
      echo "## _common"
      echo ""
      echo "通用规范已安装于 \`prompts/_common/\`，在编码决策前应加载对应文件："
      echo ""
      local f fname title
      for f in ${COMMON_FILES}; do
        fname=$(basename "$f")
        title=$(_get_title "$f")
        echo "- \`prompts/_common/${fname}\`: ${title}"
      done
      echo ""
    } >> "$out"
  fi

  success "AGENTS.md → $TARGET/AGENTS.md"
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
  echo "本脚本将规则安装到目标项目的 prompts/ 和对应 AI 工具目录。"
  echo ""

  # 目标路径
  read -r -p "目标项目路径（如 ../my-erp）: " TARGET
  TARGET="${TARGET/#~/$HOME}"
  if [ -z "$TARGET" ]; then
    error "目标路径不能为空"
  fi

  # 选择技术栈（统一展示，按类别分组，一次选择）
  echo ""
  echo "选择技术栈（多选用逗号分隔，直接回车跳过）:"

  # 自动发现 stack：扫描所有 prompts/developer.md，提取栈目录路径
  # 路径模式：
  #   backend/<lang>/<stack>/prompts/developer.md         → 后端 <lang>
  #   frontend/<framework>/prompts/developer.md           → 前端 <framework>
  #   cross-platform/<platform>/<stack>/prompts/developer.md → 跨平台 <platform>
  while IFS= read -r dev_file; do
    [ -z "$dev_file" ] && continue
    # stack_dir = dev_file 的父目录的父目录
    stack_dir=$(dirname "$(dirname "$dev_file")")
    stack_name=$(basename "$stack_dir")
    rel="${stack_dir#"$SCRIPT_DIR"/}"
    root_name=$(echo "$rel" | awk -F/ '{print $1}')
    middle_name=$(echo "$rel" | awk -F/ '{print $2}')
    case "$root_name" in
      backend)
        group_label="后端 $middle_name"
        ;;
      frontend)
        group_label="前端 $middle_name"
        ;;
      cross-platform)
        case "$middle_name" in
          mobile)  group_label="跨平台 移动" ;;
          desktop) group_label="跨平台 桌面" ;;
          miniapp) group_label="跨平台 小程序" ;;
          native)  group_label="跨平台 原生" ;;
          *)       group_label="跨平台 $middle_name" ;;
        esac
        ;;
      *) group_label="$root_name/$middle_name" ;;
    esac
    printf "  [%-15s] %s\n" "$group_label" "$stack_name"
  done < <(find "$SCRIPT_DIR" -path '*/prompts/developer.md' -not -path '*/_common/*' 2>/dev/null | sort)

  read -r -p "技术栈 (逗号分隔): " STACKS

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

  # 安装前验证：栈存在性、同名歧义、输出文件名唯一性
  validate_stacks

  # 安装通用规则（必须在栈之前，这样 convert_mdc 能注入 _common 引用）
  if [ "$INSTALL_COMMON" = true ]; then
    install_common
  fi

  # 安装每个规则栈
  for name in ${STACKS//,/ }; do
    name="${name## }"
    name="${name%% }"
    install_stack "$name"
  done

  # 合并 Codex
  merge_codex

  echo ""
  echo "==================== 安装完成 ===================="
  echo ""
  echo "📦 已安装到 $TARGET/"
  echo "   prompts:    prompts/"

  # 动态列出实际选择的工具路径（而非全部）
  local _t _sc=false _sb=false _scl=false _st=false _sl=false _sx=false
  for _t in ${TOOLS//,/ }; do
    case "$_t" in
      all) _sc=true; _sb=true; _scl=true; _st=true; _sl=true; _sx=true; break ;;
      cursor) _sc=true ;; codebuddy) _sb=true ;; claude) _scl=true ;;
      trae) _st=true ;; lingma) _sl=true ;; codex) _sx=true ;;
    esac
  done
  [ "$_sc" = true ]  && echo "   cursor:     .cursor/rules/"
  [ "$_sb" = true ]  && echo "   codebuddy:  .codebuddy/rules/"
  [ "$_scl" = true ] && echo "   claude:     .claude/agents/"
  [ "$_st" = true ]  && echo "   trae:       .trae/rules/"
  [ "$_sl" = true ]  && echo "   lingma:     .lingma/rules/"
  [ "$_sx" = true ]  && echo "   codex:      AGENTS.md"
  [ "$INSTALL_COMMON" = true ] && echo "   common:     prompts/_common/"
  echo ""
}

main "$@"
