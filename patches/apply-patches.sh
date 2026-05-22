#!/usr/bin/env bash
# ============================================================================
# Hermes Agent /switch 自动补全 — 补丁应用脚本
# ============================================================================
# 适用于 Hermes Agent >= 0.x（基于 commands.py 的 patch 注入）
# 如果 Hermes Agent 更新导致补丁失效，请提交 Issue
# ============================================================================
# 功能：为 Hermes Agent CLI 添加 /switch 和 /profile 命令的 Tab 自动补全
#       和 Ghost Text 提示功能。
#
# 用法：bash apply-patches.sh
# ============================================================================

set -euo pipefail

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# 版本检测
HERMES_VERSION=""
if command -v hermes &> /dev/null; then
    HERMES_VERSION="$(hermes --version 2>/dev/null || echo "未知版本")"
    info "Hermes Agent 版本: $HERMES_VERSION"
else
    warn "未检测到 hermes 命令"
fi

# 定位 Hermes Agent 安装目录
HERMES_DIR=""
for candidate in \
    "$HOME/.hermes/hermes-agent" \
    "$(dirname "$(command -v hermes 2>/dev/null)" 2>/dev/null)/../lib/python"*/site-packages/hermes_agent \
    "$(pip show hermes-agent 2>/dev/null | grep Location | awk '{print $2}')/hermes_agent"; do
    if [[ -d "$candidate" ]]; then
        HERMES_DIR="$candidate"
        break
    fi
done

# 尝试从 Python import 获取安装路径
if [[ -z "$HERMES_DIR" ]]; then
    HERMES_DIR="$(python3 -c "import hermes_cli; import os; print(os.path.dirname(hermes_cli.__file__))" 2>/dev/null || true)"
fi

if [[ -z "$HERMES_DIR" || ! -d "$HERMES_DIR" ]]; then
    error "无法定位 Hermes Agent 安装目录。"
    echo "  请手动确认安装路径，然后执行："
    echo "  cd /path/to/hermes-agent && patch -p1 < profile-autocomplete.patch"
    exit 1
fi

TARGET_FILE="$HERMES_DIR/commands.py"
PATCH_FILE="$(cd "$(dirname "$0")" && pwd)/profile-autocomplete.patch"

if [[ ! -f "$TARGET_FILE" ]]; then
    error "目标文件不存在: $TARGET_FILE"
    exit 1
fi

if [[ ! -f "$PATCH_FILE" ]]; then
    error "补丁文件不存在: $PATCH_FILE"
    exit 1
fi

echo -e "${BOLD}Hermes Agent /switch 自动补全 — 补丁应用${NC}"
echo ""
info "Hermes Agent 目录: $HERMES_DIR"
info "目标文件: $TARGET_FILE"
info "补丁文件: $PATCH_FILE"
echo ""

# 备份原文件
BACKUP_FILE="$TARGET_FILE.backup.$(date +%Y%m%d%H%M%S)"
cp "$TARGET_FILE" "$BACKUP_FILE"
info "已备份原文件: $BACKUP_FILE"

# 检查是否已应用过（简单检查）
if grep -q "_profile_completions" "$TARGET_FILE" 2>/dev/null; then
    warn "检测到补丁可能已经应用过（_profile_completions 已存在）"
    read -p "是否继续？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "已取消。"
        exit 0
    fi
fi

# 尝试应用补丁
echo ""
info "正在应用补丁..."

# 尝试 patch 命令
if command -v patch &> /dev/null; then
    # 用 sed 进行手动 patch（因为 diff 格式可能不完全匹配）
    echo "使用 sed 方式应用补丁..."

    python3 << 'PYTHON_SCRIPT'
import sys

target = sys.argv[1]

with open(target, 'r', encoding='utf-8') as f:
    content = f.read()

already_has = '_profile_completions' in content
if already_has:
    print("[WARN] 补丁已应用过，跳过。")
    sys.exit(0)

# 1. 添加 _profile_completions 方法（在 _personality_completions 之前）
profile_method = '''
    @staticmethod
    def _profile_completions(sub_text: str, sub_lower: str):
        """Yield completions for /profile and /switch from installed profiles."""
        try:
            from hermes_cli.profiles import list_profiles, get_active_profile_name
            from pathlib import Path as _Path

            active = get_active_profile_name()
            for p in sorted(list_profiles(), key=lambda p: p.name):
                if p.name.startswith(sub_lower) and p.name != sub_lower:
                    # Read SOUL.md first line as role title for meta
                    title = ""
                    soul_path = _Path(p.path) / "SOUL.md"
                    if soul_path.is_file():
                        try:
                            with open(soul_path, "r", encoding="utf-8") as f:
                                first_line = f.readline().strip().lstrip("# ").strip()
                            title = first_line
                        except Exception:
                            pass
                    # Build meta: show title if available, else description
                    if title:
                        meta = title[:50]
                    elif p.description:
                        meta = p.description[:50]
                    else:
                        meta = "profile"
                    # Mark active profile
                    if p.name == active:
                        display = f"{p.name} *"
                    else:
                        display = p.name
                    yield Completion(
                        p.name,
                        start_position=-len(sub_text),
                        display=display,
                        display_meta=meta,
                    )
        except Exception:
            pass

'''

# 在 _personality_completions 前插入
marker = '    @staticmethod\n    def _personality_completions('
if marker in content:
    content = content.replace(marker, profile_method + marker)
    print("[OK] 已添加 _profile_completions 方法")
else:
    print("[WARN] 未找到插入点（_personality_completions），尝试在 get_completions 前插入")
    # 备选方案
    alt_marker = '            # Dynamic completions for commands with runtime lists'
    if alt_marker in content:
        profile_dispatch = '''                if base_cmd in ("/profile", "/switch"):
                    yield from self._profile_completions(sub_text, sub_lower)
                    return
'''
        content = content.replace(alt_marker, profile_dispatch + alt_marker)

# 2. 在 get_completions 中添加 /profile 和 /switch 的分派
# 在 /model 分派之前添加
completions_dispatch = '''                if base_cmd in ("/profile", "/switch"):
                    yield from self._profile_completions(sub_text, sub_lower)
                    return
'''
model_dispatch = '                if base_cmd == "/model":\n                    yield from self._model_completions(sub_text, sub_lower)'
if model_dispatch in content and '/profile' not in content.split('def get_completions')[1].split('def _model_completions')[0]:
    content = content.replace(model_dispatch, completions_dispatch + model_dispatch, 1)
    print("[OK] 已添加 /profile /switch Tab 补全分派")

# 3. 在 SlashCommandAutoSuggest.get_suggestion 中添加 ghost text
autosuggest_dispatch = '''            if base_cmd in ("/profile", "/switch"):
                try:
                    from hermes_cli.profiles import list_profiles
                    for p in sorted(list_profiles(), key=lambda p: p.name):
                        if p.name.startswith(sub_lower) and p.name != sub_lower:
                            return Suggestion(p.name[len(sub_text):])
                except Exception:
                    pass
                return None
'''
autosuggest_model = '            if base_cmd == "/model":\n                try:\n                    from hermes_cli.model_switch'
if autosuggest_model in content and '/profile' not in content.split('class SlashCommandAutoSuggest')[1]:
    content = content.replace(autosuggest_model, autosuggest_dispatch + autosuggest_model, 1)
    print("[OK] 已添加 /profile /switch Ghost Text 提示")

with open(target, 'w', encoding='utf-8') as f:
    f.write(content)

print("[DONE] 补丁应用完成！")
PYTHON_SCRIPT

    # 检查 Python 脚本是否成功
    if grep -q "_profile_completions" "$TARGET_FILE"; then
        echo ""
        info "补丁应用成功！"
        echo ""
        info "现在你可以在 Hermes CLI 中使用："
        echo "  /switch <Tab>   自动补全 profile 名称"
        echo "  /profile <Tab>  自动补全 profile 名称"
        echo ""
        info "重启 Hermes Agent 后生效。"
    else
        echo ""
        error "补丁应用可能失败。请检查 $TARGET_FILE"
        info "可从备份恢复: cp $BACKUP_FILE $TARGET_FILE"
        exit 1
    fi
else
    error "未找到 patch 或 python3 命令"
    info "请手动编辑 $TARGET_FILE，参考 profile-autocomplete.patch 中的内容"
    exit 1
fi
