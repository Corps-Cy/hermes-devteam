#!/usr/bin/env bash
# ============================================================================
# Hermes AI 多 Profile 团队配置 — 一键安装脚本
# ============================================================================
# 功能：在全新的 Hermes Agent 安装上，自动创建 11 个专业 Profile
# 用法：chmod +x install.sh && ./install.sh [选项]
#
# 选项：
#   --model-heavy <model>   为 reasoning tier 指定模型（如 claude-sonnet-4）
#   --model-fast <model>    为 execution tier 指定模型（如 gpt-4o-mini）
#   --provider <name>       指定模型 provider（如 openrouter、anthropic）
#   --base-url <url>        指定 API base URL
#   --apply-patches         安装后自动应用 /switch 自动补全补丁
#   --skip-models           只安装角色定义（SOUL.md），不配置模型
#   --dry-run               只显示将要执行的操作，不实际执行
#   --help                  显示帮助信息
# ============================================================================

set -euo pipefail

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---- 默认参数 ----
MODEL_HEAVY=""
MODEL_FAST=""
PROVIDER=""
BASE_URL=""
APPLY_PATCHES=false
SKIP_MODELS=false
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- Tier 中的 Profile 列表 ----
PROFILE_REASONING="architect ceo coder designer pm qa data ml"
PROFILE_EXECUTION="devops orchestrator pmo"
ALL_PROFILES="$PROFILE_REASONING $PROFILE_EXECUTION"

# ---- 帮助信息 ----
show_help() {
    echo -e "${BOLD}Hermes AI 多 Profile 团队配置 — 安装脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --model-heavy <model>   为 reasoning tier 指定模型"
    echo "  --model-fast <model>    为 execution tier 指定模型"
    echo "  --provider <name>       指定模型 provider（如 openrouter、anthropic）"
    echo "  --base-url <url>        指定 API base URL"
    echo "  --apply-patches         安装后自动应用 /switch 自动补全补丁"
    echo "  --skip-models           只安装角色定义，不配置模型"
    echo "  --dry-run               只显示将要执行的操作，不实际执行"
    echo "  --help                  显示帮助信息"
    echo ""
    echo "模型 Tier 说明:"
    echo "  reasoning（重型）: $PROFILE_REASONING"
    echo "  execution（轻型）: $PROFILE_EXECUTION"
    echo ""
    echo "示例:"
    echo "  $0                                                       # 只装角色定义"
    echo "  $0 --model-heavy claude-sonnet-4 --model-fast gpt-4o-mini"
    echo "  $0 --model-heavy glm-5.1 --model-fast glm-5-turbo --provider zai"
    echo "  $0 --provider openrouter --model-heavy anthropic/claude-sonnet-4"
    echo "  $0 --apply-patches                                       # 启用 /switch 补全"
    echo "  $0 --dry-run                                             # 预览操作"
}

# ---- 日志函数 ----
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "${BLUE}[STEP]${NC} $*"; }

# ---- 参数解析 ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model-heavy)    MODEL_HEAVY="$2"; shift 2 ;;
        --model-fast)     MODEL_FAST="$2"; shift 2 ;;
        --provider)       PROVIDER="$2"; shift 2 ;;
        --base-url)       BASE_URL="$2"; shift 2 ;;
        --apply-patches)  APPLY_PATCHES=true; shift ;;
        --skip-models)    SKIP_MODELS=true; shift ;;
        --dry-run)        DRY_RUN=true; shift ;;
        --help|-h)        show_help; exit 0 ;;
        *) error "未知参数: $1"; show_help; exit 1 ;;
    esac
done

# ---- 从 model-assignments.yaml 读取用户自定义模型（如果有）----
read_yaml_models() {
    local yaml="$SCRIPT_DIR/model-assignments.yaml"
    if [[ ! -f "$yaml" ]]; then
        return
    fi

    # 检查是否有 models: 段且未被注释
    # 简单解析：找到非注释的 reasoning: 和 execution: 行
    local in_models=false
    while IFS= read -r line; do
        # 跳过注释和空行
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        if [[ "$line" =~ ^[[:space:]]*models: ]]; then
            in_models=true
            continue
        fi

        if $in_models; then
            # 遇到其他顶层 key，结束
            if [[ "$line" =~ ^[a-z] && ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
            if [[ "$line" =~ reasoning:[[:space:]]*\"(.+)\" ]]; then
                [[ -z "$MODEL_HEAVY" ]] && MODEL_HEAVY="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ execution:[[:space:]]*\"(.+)\" ]]; then
                [[ -z "$MODEL_FAST" ]] && MODEL_FAST="${BASH_REMATCH[1]}"
            fi
        fi
    done < "$yaml"
}

read_yaml_models

# ---- 前置检查 ----
check_prerequisites() {
    step "检查前置条件..."

    # 检查 hermes 命令
    if ! command -v hermes &> /dev/null; then
        error "未找到 hermes 命令。请先安装 Hermes Agent。"
        echo "  安装方式参考: https://hermes-agent.nousresearch.com/docs"
        exit 1
    fi
    info "hermes 命令已找到"
    info "Hermes Agent 已安装"

    # 检查项目文件完整性
    local missing=()
    for profile in $ALL_PROFILES; do
        if [[ ! -f "$SCRIPT_DIR/profiles/$profile/SOUL.md" ]]; then
            missing+=("$profile/SOUL.md")
        fi
        if [[ ! -f "$SCRIPT_DIR/profiles/$profile/profile.yaml" ]]; then
            missing+=("$profile/profile.yaml")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "以下文件缺失:"
        for f in "${missing[@]}"; do
            echo "  - $f"
        done
        exit 1
    fi
    info "所有 Profile 文件完整（共 $(echo $ALL_PROFILES | wc -w) 个）"
}

# ---- 获取 Hermes Profile 目录 ----
get_hermes_profiles_dir() {
    echo "$HOME/.hermes/profiles"
}

# ---- 创建单个 Profile ----
create_profile() {
    local name="$1"
    local model="${2:-}"
    local profiles_dir
    profiles_dir="$(get_hermes_profiles_dir)"
    local profile_path="$profiles_dir/$name"

    # 检查是否已存在
    if [[ -d "$profile_path" ]]; then
        warn "Profile '$name' 已存在，跳过创建（将更新 SOUL.md 和 profile.yaml）"
    else
        if $DRY_RUN; then
            info "[dry-run] 将创建 Profile: $name"
        else
            if hermes profile create "$name" 2>/dev/null; then
                info "Profile '$name' 创建成功"
            else
                warn "Profile '$name' 创建失败，尝试手动创建目录..."
                mkdir -p "$profile_path"
            fi
        fi
    fi

    # 复制 SOUL.md
    if $DRY_RUN; then
        info "[dry-run] 将复制 SOUL.md → $profile_path/SOUL.md"
    else
        cp "$SCRIPT_DIR/profiles/$name/SOUL.md" "$profile_path/SOUL.md"
        info "  SOUL.md 已更新"
    fi

    # 写入 profile.yaml
    if $DRY_RUN; then
        info "[dry-run] 将写入 profile.yaml → $profile_path/profile.yaml"
    else
        cp "$SCRIPT_DIR/profiles/$name/profile.yaml" "$profile_path/profile.yaml"
        info "  profile.yaml 已更新"
    fi

    # 设置模型（如果指定且不跳过）
    if ! $SKIP_MODELS && [[ -n "$model" ]]; then
        if $DRY_RUN; then
            info "[dry-run] hermes -p $name config set model.default $model"
        else
            hermes -p "$name" config set model.default "$model" 2>/dev/null || \
                warn "  设置模型失败: $model（可手动执行: hermes -p $name config set model.default $model）"
        fi
        if [[ -n "$PROVIDER" ]]; then
            if $DRY_RUN; then
                info "[dry-run] hermes -p $name config set model.provider $PROVIDER"
            else
                hermes -p "$name" config set model.provider "$PROVIDER" 2>/dev/null || \
                    warn "  设置 provider 失败: $PROVIDER"
            fi
        fi
        if [[ -n "$BASE_URL" ]]; then
            if $DRY_RUN; then
                info "[dry-run] hermes -p $name config set model.base_url $BASE_URL"
            else
                hermes -p "$name" config set model.base_url "$BASE_URL" 2>/dev/null || true
            fi
        fi
        info "  模型: $model${PROVIDER:+ (provider: $PROVIDER)}"
    fi
}

# ---- 安装所有 Profile ----
install_profiles() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}        Hermes AI 多 Profile 团队配置 — 安装${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    if [[ -n "$MODEL_HEAVY" ]]; then
        info "Reasoning 模型: $MODEL_HEAVY"
    else
        warn "Reasoning 模型: 未指定（--model-heavy）"
    fi
    if [[ -n "$MODEL_FAST" ]]; then
        info "Execution 模型: $MODEL_FAST"
    else
        warn "Execution 模型: 未指定（--model-fast）"
    fi
    [[ -n "$PROVIDER" ]] && info "Provider: $PROVIDER"
    [[ -n "$BASE_URL" ]] && info "Base URL: $BASE_URL"
    $SKIP_MODELS && warn "模式: 只安装角色定义（跳过模型配置）"
    $DRY_RUN && warn "模式: 预览（不会实际执行）"
    echo ""

    local count=0
    local total=$(echo $ALL_PROFILES | wc -w | tr -d ' ')

    # Reasoning Tier（重型）
    step "安装 Reasoning Tier — 深度推理角色..."
    for profile in $PROFILE_REASONING; do
        count=$((count + 1))
        echo -e "  ${BOLD}[$count/$total]${NC} $profile"
        create_profile "$profile" "$MODEL_HEAVY"
    done

    echo ""
    # Execution Tier（轻型）
    step "安装 Execution Tier — 执行调度角色..."
    for profile in $PROFILE_EXECUTION; do
        count=$((count + 1))
        echo -e "  ${BOLD}[$count/$total]${NC} $profile"
        create_profile "$profile" "$MODEL_FAST"
    done
}

# ---- 应用补丁 ----
apply_patches() {
    if ! $APPLY_PATCHES; then
        return
    fi

    echo ""
    step "应用 /switch 自动补全补丁..."

    local patch_script="$SCRIPT_DIR/patches/apply-patches.sh"
    if [[ -f "$patch_script" ]]; then
        if $DRY_RUN; then
            info "[dry-run] 将执行: $patch_script"
        else
            bash "$patch_script"
        fi
    else
        warn "未找到 apply-patches.sh，跳过补丁应用"
    fi
}

# ---- 安装总结 ----
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}                   安装完成！${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}已安装的 Profile:${NC}"
    echo ""
    echo -e "  ${CYAN}Reasoning Tier（深度推理角色）${NC} \
${MODEL_HEAVY:+→ $MODEL_HEAVY}"
    echo "    architect    技术架构师"
    echo "    ceo          商业 CEO"
    echo "    coder        全栈工程师"
    echo "    designer     UI/UX 设计师"
    echo "    pm           产品经理"
    echo "    qa           QA 审计师"
    echo "    data         数据工程师"
    echo "    ml           AI/ML 工程师"
    echo ""
    echo -e "  ${CYAN}Execution Tier（执行调度角色）${NC} \
${MODEL_FAST:+→ $MODEL_FAST}"
    echo "    devops       运维工程师"
    echo "    orchestrator  项目总指挥"
    echo "    pmo          项目管理"
    echo ""
    echo -e "${BOLD}使用方式:${NC}"
    echo ""
    echo "  # 切换到某个 Profile"
    echo "  hermes -p architect"
    echo ""
    echo "  # 在会话中切换 Profile"
    echo "  /switch coder"
    echo "  /profile designer"
    echo ""
    echo -e "${BOLD}自定义模型:${NC}"
    echo ""
    echo "  # 为所有 reasoning 角色切换模型"
    echo "  for p in architect ceo coder designer pm qa data ml; do"
    echo "    hermes -p \$p config set model.default <your-model>"
    echo "  done"
    echo ""
    echo "  # 为单个 Profile 切换模型"
    echo "  hermes -p coder config set model.default <model>"
    echo ""
    echo "  # 编辑角色定义"
    echo "  vim ~/.hermes/profiles/<name>/SOUL.md"
    echo ""
    if $APPLY_PATCHES; then
        info "/switch 自动补全补丁已应用"
    else
        info "提示: 运行 ./patches/apply-patches.sh 可启用 /switch Tab 自动补全"
    fi
}

# ---- 主流程 ----
main() {
    check_prerequisites
    install_profiles
    apply_patches
    print_summary
}

main "$@"
