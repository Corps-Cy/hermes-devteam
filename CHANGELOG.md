# Changelog

所有重要更改都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/)，
版本号遵循 [Semantic Versioning](https://semver.org/)。

## [0.1.0] - 2025-05-22

### 新增
- 11 个专业 Profile：architect、ceo、coder、data、designer、devops、ml、orchestrator、pm、pmo、qa
- 一键安装脚本 `install.sh`，支持 `--model-heavy`、`--model-fast`、`--provider`、`--base-url`、`--apply-patches`、`--skip-models`、`--dry-run` 参数
- Tier 分层模型分配（Reasoning / Execution），通过 `model-assignments.yaml` 配置
- `/switch` 和 `/profile` Tab 自动补全补丁
- Provider 无关设计，支持 Claude、GPT、GLM、Gemini、Llama 等任意模型
- 卸载功能 `--uninstall`
- `.editorconfig` 统一编码风格

[0.1.0]: https://github.com/Corps-Cy/hermes-devteam/releases/tag/v0.1.0
