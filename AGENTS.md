# Codex 执行规则

## 项目
SwiftUI iOS App：AI Screenshot Assistant

## 产品目标
打造一个 AI Native 的截图理解助手，而不仅仅是 OCR 工具。

核心体验：
Screenshot
→ OCR
→ AI Understanding
→ Streaming Summary
→ Follow-up Chat

## 开发规则
- 不要重构整个项目
- 每次只实现一个小功能
- 保持现有 UI 风格
- 使用 SwiftUI + MVVM
- 业务逻辑放在 Services
- 页面放在 Features
- 可复用 UI 放在 Components
- 所有功能必须可编译
- 不要硬编码 API Key
- 尽量避免 TODO
- 完成后自动 build
- 不修改无关文件

## 当前优先级
1. Screenshot Type Detection
2. Prompt Router
3. Specialized Summary
4. Result UI Enhancement
5. Screenshot Memory