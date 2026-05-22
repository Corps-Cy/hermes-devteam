# Hermes AI 多 Profile 团队配置

> 一键安装 11 个专业 AI Agent Profile，打造完整的软件研发团队。
> 支持任意模型 Provider — Claude、GPT、GLM、Gemini、Llama 等。

## 这是什么？

本项目为 [Hermes Agent](https://hermes-agent.nousresearch.com/) 提供了一套**预配置的多 Profile 团队设置**。

通过为不同角色创建独立的 Profile（SOUL.md 角色定义 + 模型分配），你可以在 Hermes AI 中快速切换不同的专家角色，像管理一个真正的软件团队一样使用 AI。

**核心设计理念：角色定义与模型解耦。** Profile 只定义"这个角色做什么"，不绑定任何特定模型。你可以根据自己的 Provider 和预算自由搭配。

## Profile 一览

### Reasoning Tier — 深度推理角色

需要强推理、复杂分析、高质量生成的角色。

| Profile | 角色 | 说明 |
|---------|------|------|
| `architect` | 系统架构师 | 系统设计、技术选型、架构评审 |
| `ceo` | 商业 CEO | 商业决策、战略规划、组织管理 |
| `coder` | 全栈工程师 | 代码开发、调试、重构 |
| `designer` | UI/UX 设计师 | 界面设计、用户体验、交互规范 |
| `pm` | 产品经理 | 需求分析、产品规划、用户故事 |
| `qa` | QA 审计师 | 质量保障、代码审计、测试策略 |
| `data` | 数据工程师 | 数据管道、ETL、数据建模 |
| `ml` | AI/ML 工程师 | 模型训练、MLOps、AI 开发 |

### Execution Tier — 执行调度角色

偏重执行、调度、模板化工作，需要快速响应和稳定工具调用。

| Profile | 角色 | 说明 |
|---------|------|------|
| `devops` | 运维工程师 | CI/CD、容器化、基础设施 |
| `orchestrator` | 项目总指挥 | 任务分发、进度追踪、团队协调 |
| `pmo` | 项目管理 | 流程管理、模板化、标准化 |

## 为什么分两个 Tier？

不同角色对模型能力的需求不同：

- **Reasoning 角色**需要深度推理、创意生成、长文档理解 — 适合用旗舰模型
- **Execution 角色**偏重工具调用、任务调度、模板化输出 — 用快速模型即可，性价比更高

这个分法是建议性的，你可以根据实际情况自由调整。

## 快速开始

### 前置条件

- 已安装 [Hermes Agent](https://hermes-agent.nousresearch.com/docs)
- 已配置至少一个模型 Provider

### 一键安装

```bash
git clone https://github.com/yourusername/hermes-profiles.git
cd hermes-profiles
chmod +x install.sh

# 方式一：只安装角色定义（不配置模型，推荐先用默认模型试跑）
./install.sh

# 方式二：安装角色并指定模型
./install.sh --model-heavy claude-sonnet-4 --model-fast gpt-4o-mini
```

### 高级选项

```bash
# 指定 Provider
./install.sh --model-heavy glm-5.1 --model-fast glm-5-turbo --provider zai

# 使用 OpenRouter 接入不同模型
./install.sh \
  --model-heavy anthropic/claude-sonnet-4 \
  --model-fast openai/gpt-4o-mini \
  --provider openrouter

# 只装角色定义，不配模型
./install.sh --skip-models

# 同时启用 /switch Tab 补全
./install.sh --model-heavy claude-sonnet-4 --model-fast gpt-4o-mini --apply-patches

# 预览将要执行的操作
./install.sh --dry-run
```

### 通过配置文件指定模型

你也可以在 `model-assignments.yaml` 中取消 `models:` 段的注释：

```yaml
models:
  reasoning: "claude-sonnet-4"
  execution: "gpt-4o-mini"
```

安装脚本会自动读取。命令行参数 `--model-heavy` / `--model-fast` 优先级更高。

## 使用方式

安装完成后，在 Hermes Agent 中使用：

```bash
# 启动时指定 Profile
hermes -p architect

# 在会话中切换 Profile
/switch coder
/profile designer

# 输入 /switch 后按 Tab 自动补全（需应用补丁）
/switch <Tab>
```

## 项目结构

```
hermes-profiles/
├── README.md                    # 本文件
├── LICENSE                      # MIT 许可证
├── install.sh                   # 一键安装脚本
├── model-assignments.yaml       # Tier 分层 + 可选模型配置
├── profiles/                    # 所有 Profile 文件
│   ├── architect/
│   │   ├── SOUL.md              # 架构师角色定义
│   │   └── profile.yaml         # 架构师元数据
│   ├── ceo/
│   ├── coder/
│   ├── data/
│   ├── designer/
│   ├── devops/
│   ├── ml/
│   ├── orchestrator/
│   ├── pm/
│   ├── pmo/
│   └── qa/
└── patches/                     # CLI 增强补丁
    ├── profile-autocomplete.patch  # /switch Tab 补全
    └── apply-patches.sh            # 补丁应用脚本
```

## 自定义

### 修改角色定义

每个 Profile 的角色行为由 `SOUL.md` 定义。编辑方式：

```bash
# 方式一：直接编辑安装后的文件
vim ~/.hermes/profiles/coder/SOUL.md

# 方式二：在本项目中修改后重新安装
vim profiles/coder/SOUL.md
./install.sh
```

### 调整模型分配

```bash
# 为所有 reasoning 角色切换模型
for p in architect ceo coder designer pm qa data ml; do
  hermes -p $p config set model.default <your-model>
done

# 为单个 Profile 切换模型
hermes -p coder config set model.default <model>

# 也可以全部用同一个模型
for p in architect ceo coder designer devops ml orchestrator pm pmo qa data; do
  hermes -p $p config set model.default gpt-4o
done
```

### 添加新 Profile

1. 在 `profiles/` 下创建新目录
2. 编写 `SOUL.md`（角色定义）
3. 编写 `profile.yaml`（元数据）
4. 更新 `install.sh` 中的 Profile 列表
5. 运行 `./install.sh`

### 添加 /switch 自动补全

如果你希望在输入 `/switch` 后按 Tab 自动补全 Profile 名称：

```bash
./patches/apply-patches.sh
```

这个补丁会为 Hermes CLI 添加：
- Tab 补全：`/switch <Tab>` 显示所有可用 Profile
- Ghost Text：输入 `/switch` 后自动显示匹配的 Profile 名
- 角色标题：补全列表中显示每个 Profile 的角色名称
- 当前标记：当前激活的 Profile 后显示 `*` 号

## Profile 角色说明

### architect — 系统架构师
负责系统整体设计、技术选型、架构评审。擅长设计高可用、高性能的系统架构。

### ceo — 商业 CEO
具备全局商业视角，擅长战略规划、商业决策和资源分配。适合产品方向讨论和商业分析。

### coder — 全栈工程师
熟练掌握多种编程语言和技术栈，擅长代码开发、调试、重构和代码审查。

### data — 数据工程师
专注于数据管道设计、ETL 流程、数据建模和数据分析。擅长处理大规模数据。

### designer — UI/UX 设计师
具备设计思维，擅长界面设计、用户体验优化和交互设计。熟悉设计系统和组件库。

### devops — 运维工程师
擅长 CI/CD 流水线、容器化（Docker/K8s）、基础设施即代码和监控告警。

### ml — AI/ML 工程师
专注于机器学习模型开发、训练、部署和 MLOps。熟悉主流 ML 框架和工具链。

### orchestrator — 项目总指挥
负责任务分发、进度追踪和团队协调。擅长将复杂项目分解为可执行的子任务。

### pm — 产品经理
擅长需求分析、产品规划、用户研究和优先级排序。能够输出清晰的 PRD。

### pmo — 项目管理
专注于流程管理、标准化和模板化。擅长项目进度管理和风险管控。

### qa — QA 审计师
擅长质量保障、代码审计、测试策略设计和安全审计。确保交付质量。

## 许可证

MIT License — 详见 [LICENSE](LICENSE)

## 贡献

欢迎提交 Issue 和 PR！

- 发现角色定义不完善？→ 提交 Issue 或直接修改 SOUL.md
- 有新的角色想法？→ 创建新 Profile 并提交 PR
- 模型分配建议？→ 提交 Issue 讨论
- 支持新的 Provider？→ 提交配置示例
