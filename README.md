<p align="center">
  <h1 align="center">🛠️ Hermes DevTeam</h1>
  <p align="center">
    一键为 <a href="https://hermes-agent.nousresearch.com/">Hermes Agent</a> 配置 11 个专业 AI Profile，组建完整的软件工程团队
  </p>
  <p align="center">
    <code>architect</code> · <code>pm</code> · <code>designer</code> · <code>coder</code> · <code>qa</code> · <code>devops</code> · <code>ml</code> · <code>data</code> · <code>ceo</code> · <code>orchestrator</code> · <code>pmo</code>
  </p>
</p>

---

## 它是什么

Hermes DevTeam 为 [Hermes Agent](https://hermes-agent.nousresearch.com/) 提供了一套**预配置的多 Profile 团队**。每个 Profile 包含独立的角色定义（SOUL.md），模拟真实软件工程团队的分工协作。

你可以在不同角色之间快速切换，像管理一个真正的开发团队一样使用 AI：

```
hermes -p architect     # 切到架构师讨论系统设计
/switch coder           # 切到全栈工程师开始写代码
/switch qa              # 切到 QA 做代码审计
```

**核心原则：角色定义与模型完全解耦。** 你可以用 Claude、GPT、GLM、Gemini、Llama 或任何 Provider — Profile 只定义"这个角色做什么"，模型由你自由搭配。

---

## Demo

> 将来可以在这里展示安装和使用过程的截图/GIF

<br/>

<p align="center">
  <img src="docs/demo.svg" alt="Hermes DevTeam Demo" width="600">
</p>

---

## 快速开始

### 前置条件

- 已安装 [Hermes Agent](https://hermes-agent.nousresearch.com/docs)
- 已配置至少一个模型 Provider

### 一键安装

```bash
git clone https://github.com/Corps-Cy/hermes-devteam.git
cd hermes-devteam
chmod +x install.sh

# 最简安装 — 只部署角色定义，使用你当前的默认模型
./install.sh

# 安装角色并指定模型
./install.sh --model-heavy claude-sonnet-4 --model-fast gpt-4o-mini
```

安装完成后即可使用：

```bash
hermes -p architect    # 用架构师角色启动
/switch coder          # 会话中切换角色
/switch <Tab>          # Tab 补全（需应用补丁）
```

---

## 团队阵容

### Reasoning Tier — 深度推理

需要强推理、复杂分析、高质量生成的角色，建议配旗舰模型。

| Profile | 角色 | 职责 | SOUL.md |
|---------|------|------|---------|
| `architect` | 技术架构师 | 系统设计、技术选型、架构评审、技术文档 | 214 行 |
| `pm` | 高级产品经理 | 需求分析、PRD、用户故事、优先级排序 | 221 行 |
| `designer` | 高级 UI/UX 设计师 | 界面设计、交互规范、设计系统、HTML 原型 | 187 行 |
| `coder` | 顶级全栈工程师 | 代码开发、调试、重构、代码审查 | 144 行 |
| `qa` | QA 审计工程师 | 代码审计、安全审计、测试策略、质量把关 | 182 行 |
| `data` | 数据工程师/分析师 | 数据管道、ETL、数据建模、BI 仪表盘 | 255 行 |
| `ml` | AI/ML 工程师 | LLM 集成、RAG、微调、MLOps、AI 产品 | 246 行 |
| `ceo` | 商业 CEO | 战略规划、商业决策、ROI 分析、市场洞察 | 131 行 |

### Execution Tier — 执行调度

偏重工具调用、任务编排、模板化工作，用快速模型即可。

| Profile | 角色 | 职责 | SOUL.md |
|---------|------|------|---------|
| `devops` | 运维部署工程师 | CI/CD、Docker/K8s、基础设施、监控告警 | 270 行 |
| `orchestrator` | 项目总指挥 | 任务分解、多 Profile 调度、进度管理 | 321 行 |
| `pmo` | 项目/版本管理 | 需求跟踪、Sprint 规划、变更日志、发布管理 | 215 行 |

---

## 为什么分 Tier

不同角色对模型能力的需求差异很大：

- **Reasoning 角色**需要深度推理、创意生成、长文档理解 → 适合旗舰模型（Claude Sonnet/Opus、GPT-4o、GLM-5.1 等）
- **Execution 角色**偏重工具调用、任务编排 → 快速模型就够了（GPT-4o-mini、Claude Haiku、GLM-5-Turbo 等），成本更低

这只是建议分组，你可以完全按自己的判断来分配模型。

---

## 安装选项

```bash
# 指定模型和 Provider
./install.sh --model-heavy claude-sonnet-4 --model-fast gpt-4o-mini --provider anthropic

# 使用 OpenRouter 接入不同模型
./install.sh \
  --model-heavy anthropic/claude-sonnet-4 \
  --model-fast openai/gpt-4o-mini \
  --provider openrouter

# 只装角色定义，跳过模型配置
./install.sh --skip-models

# 同时启用 /switch Tab 补全
./install.sh --model-heavy claude-sonnet-4 --model-fast gpt-4o-mini --apply-patches

# 预览操作（不实际执行）
./install.sh --dry-run
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `--model-heavy <model>` | 为 Reasoning Tier 指定模型 |
| `--model-fast <model>` | 为 Execution Tier 指定模型 |
| `--provider <name>` | 模型 Provider（如 `anthropic`、`openai`、`openrouter`） |
| `--base-url <url>` | 自定义 API 端点 |
| `--apply-patches` | 安装后自动应用 `/switch` 补全补丁 |
| `--skip-models` | 只安装角色定义，不配置模型 |
| `--dry-run` | 预览模式，只显示将要执行的操作 |

### 配置文件方式

也可以编辑 `model-assignments.yaml`，取消 `models:` 段的注释并填入你的模型：

```yaml
models:
  reasoning: "claude-sonnet-4"
  execution: "claude-haiku-4"
```

命令行参数优先级高于配置文件。

---

## 自定义

### 修改角色定义

```bash
# 直接编辑已安装的文件
vim ~/.hermes/profiles/coder/SOUL.md

# 或在本项目中修改后重新安装
vim profiles/coder/SOUL.md
./install.sh
```

### 调整模型分配

```bash
# 为 reasoning tier 全部切换
for p in architect ceo coder designer pm qa data ml; do
  hermes -p $p config set model.default <your-model>
done

# 为单个 Profile 切换
hermes -p coder config set model.default <model>

# 全部用同一个模型
for p in architect ceo coder designer devops ml orchestrator pm pmo qa data; do
  hermes -p $p config set model.default gpt-4o
done
```

### 添加新角色

1. 在 `profiles/` 下创建新目录（如 `profiles/security/`）
2. 编写 `SOUL.md` — 角色定义文件
3. 编写 `profile.yaml` — 元数据（description、description_auto: false）
4. 更新 `model-assignments.yaml` 将新角色加入对应 tier
5. 运行 `./install.sh`

---

## /switch 自动补全（可选增强）

安装补丁后，在 Hermes CLI 中输入 `/switch` 按 Tab 即可补全 Profile 名称：

```bash
./patches/apply-patches.sh
```

补丁功能：
- Tab 补全：`/switch <Tab>` 显示所有可用 Profile
- Ghost Text：输入 `/switch` 后自动显示匹配的 Profile 名
- 角色标题：补全列表中显示每个 Profile 的角色名称
- 当前标记：当前激活的 Profile 后显示 `*` 号

---

## 项目结构

```
hermes-devteam/
├── README.md                         # 本文件
├── CHANGELOG.md                    # 更新日志
├── LICENSE                           # MIT
├── install.sh                        # 一键安装脚本（支持多种参数）
├── model-assignments.yaml            # Tier 分层定义 + 可选模型配置
├── docs/                           # 文档和截图
├── profiles/
│   ├── architect/  {SOUL.md, profile.yaml}
│   ├── ceo/         {SOUL.md, profile.yaml}
│   ├── coder/       {SOUL.md, profile.yaml}
│   ├── data/        {SOUL.md, profile.yaml}
│   ├── designer/    {SOUL.md, profile.yaml}
│   ├── devops/      {SOUL.md, profile.yaml}
│   ├── ml/          {SOUL.md, profile.yaml}
│   ├── orchestrator/{SOUL.md, profile.yaml}
│   ├── pm/          {SOUL.md, profile.yaml}
│   ├── pmo/         {SOUL.md, profile.yaml}
│   └── qa/          {SOUL.md, profile.yaml}
└── patches/
    ├── profile-autocomplete.patch    # /switch Tab 补全补丁
    └── apply-patches.sh             # 补丁应用脚本
```

---

## 许可证

[MIT License](LICENSE)

---

## 贡献

欢迎 PR 和 Issue：

- 想添加新角色？→ 在 `profiles/` 下创建，提交 PR
- 角色定义有问题？→ 修改 SOUL.md，提交 PR
- 有 Provider 配置建议？→ 提交 Issue 讨论
- 发现 Bug？→ 提交 Issue
