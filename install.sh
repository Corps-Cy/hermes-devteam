#!/usr/bin/env bash
# ============================================================================
# Hermes AI 多 Profile 团队配置 — 一键安装脚本
# ============================================================================
# 功能：在全新的 Hermes Agent 安装上，自动创建 11 个专业 Profile
# 用法：chmod +x install.sh && ./install.sh [选项]
#
# 选项：
#   --provider <name>   指定模型 provider（默认：zai）
#   --base-url <url>    指定 API base URL
#   --apply-patches     安装后自动应用 /switch 自动补全补丁
#   --dry-run           只显示将要执行的操作，不实际执行
#   --help              显示帮助信息
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
PROVIDER="zai"
BASE_URL="https://open.bigmodel.cn/api/coding/paas/v4"
APPLY_PATCHES=false
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- 帮助信息 ----
show_help() {
    echo -e "${BOLD}Hermes AI 多 Profile 团队配置 — 安装脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --provider <name>   指定模型 provider（默认: zai）"
    echo "  --base-url <url>    指定 API base URL"
    echo "  --apply-patches     安装后自动应用 /switch 自动补全补丁"
    echo "  --dry-run           只显示将要执行的操作，不实际执行"
    echo "  --help              显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                              # 默认安装（zai provider）"
    echo "  $0 --provider openrouter        # 使用 OpenRouter"
    echo "  $0 --apply-patches              # 安装并应用自动补丁"
    echo "  $0 --dry-run                    # 预览操作"
}

# ---- 日志函数 ----
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "${BLUE}[STEP]${NC} $*"; }

# ---- 参数解析 ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --provider)    PROVIDER="$2"; shift 2 ;;
        --base-url)    BASE_URL="$2"; shift 2 ;;
        --apply-patches) APPLY_PATCHES=true; shift ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --help|-h)     show_help; exit 0 ;;
        *) error "未知参数: $1"; show_help; exit 1 ;;
    esac
done

# ---- Profile 列表和模型分配 ----
# GLM-5.1（旗舰）：深度推理角色
PROFILE_GLM51="architect ceo coder designer pm qa data ml"
# GLM-5-Turbo（快速）：执行型角色
PROFILE_GLM5T="devops orchestrator pmo"

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

    # 检查 profiles 目录
    local profiles_dir
    profiles_dir="$(hermes -p default config get model.provider 2>/dev/null && echo "ok" || true)"
    info "Hermes Agent 已安装"

    # 检查项目文件完整性
    if [[ ! -f "$SCRIPT_DIR/model-assignments.yaml" ]]; then
        error "未找到 model-assignments.yaml，请确认在项目根目录运行"
        exit 1
    fi

    local missing=()
    for profile in architect ceo coder data designer devops ml orchestrator pm pmo qa; do
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
    info "所有 Profile 文件完整"
}

# ---- 获取 Hermes Profile 目录 ----
get_hermes_profiles_dir() {
    # 通常在 ~/.hermes/profiles/
    echo "$HOME/.hermes/profiles"
}

# ---- 创建单个 Profile ----
create_profile() {
    local name="$1"
    local model="$2"
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

    # 设置模型
    if $DRY_RUN; then
        info "[dry-run] hermes -p $name config set model.default $model"
        info "[dry-run] hermes -p $name config set model.provider $PROVIDER"
    else
        hermes -p "$name" config set model.default "$model" 2>/dev/null || \
            warn "  设置模型失败: $model（可手动执行: hermes -p $name config set model.default $model）"
        hermes -p "$name" config set model.provider "$PROVIDER" 2>/dev/null || \
            warn "  设置 provider 失败: $PROVIDER"
        info "  模型: $model (provider: $PROVIDER)"
    fi

    # 设置 base_url（如果指定）
    if [[ -n "$BASE_URL" ]]; then
        if $DRY_RUN; then
            info "[dry-run] hermes -p $name config set model.base_url $BASE_URL"
        else
            hermes -p "$name" config set model.base_url "$BASE_URL" 2>/dev/null || true
        fi
    fi
}

# ---- 安装所有 Profile ----
install_profiles() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}        Hermes AI 多 Profile 团队配置 — 安装${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    info "Provider: $PROVIDER"
    info "Base URL: $BASE_URL"
    if $DRY_RUN; then
        warn "模式: 预览（不会实际执行）"
    fi
    echo ""

    local count=0
    local total=11

    # GLM-5.1 Profile
    step "安装 GLM-5.1 旗舰模型 Profile（需要深度推理的角色）..."
    for profile in $PROFILE_GLM51; do
        count=$((count + 1))
        echo -e "  ${BOLD}[$count/$total]${NC} $profile"
        create_profile "$profile" "glm-5.1"
    done

    echo ""
    # GLM-5-Turbo Profile
    step "安装 GLM-5-Turbo 快速模型 Profile（执行型角色）..."
    for profile in $PROFILE_GLM5T; do
        count=$((count + 1))
        echo -e "  ${BOLD}[$count/$total]${NC} $profile"
        create_profile "$profile" "glm-5-turbo"
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
    echo -e "  ${CYAN}GLM-5.1（旗舰模型 — 深度推理角色）:${NC}"
    echo "    architect    技术架构师"
    echo "    ceo          商业 CEO"
    echo "    coder        全栈工程师"
    echo "    designer     UI/UX 设计师"
    echo "    pm           产品经理"
    echo "    qa           QA 审计师"
    echo "    data         数据工程师"
    echo "    ml           AI/ML 工程师"
    echo ""
    echo -e "  ${CYAN}GLM-5-Turbo（快速模型 — 执行型角色）:${NC}"
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
    echo -e "${BOLD}自定义建议:${NC}"
    echo ""
    echo "  # 修改某个 Profile 的模型"
    echo "  hermes -p <name> config set model.default <model>"
    echo ""
    echo "  # 编辑某个 Profile 的 SOUL.md（角色定义）"
    echo "  vim ~/.hermes/profiles/<name>/SOUL.md"
    echo ""
    echo -e "${BOLD}模型分配策略:${NC}"
    echo "  - 深度推理角色（architect/ceo/coder/designer/pm/qa/data/ml）→ GLM-5.1"
    echo "  - 执行调度角色（devops/orchestrator/pmo）→ GLM-5-Turbo"
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
