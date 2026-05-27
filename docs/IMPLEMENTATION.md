# AI Screenshot Assistant 特色图片理解能力落地方案

> 目标：把 App 从「OCR + 简单总结」升级为「AI Screenshot Intelligence / Screenshot Copilot」  
> 技术栈：SwiftUI + Vision OCR + OpenAI Vision/Streaming + SwiftData + App Group + WidgetKit  
> 面向 Codex/Cursor：本文包含产品规划、UI 细节、技术细节、工程结构、数据模型、Prompt Router、代码规则与落地任务拆解。

---

## 0. 核心升级方向

当前 App 的能力：

```text
截图 → OCR → 总结
```

下一阶段升级为：

```text
截图 → OCR + 视觉理解 → 截图类型识别 → Prompt Router → 专属 AI 结果 → 追问/行动/记忆
```

产品不再定位为：

```text
AI OCR 工具
```

而是：

```text
AI Screenshot Intelligence
```

核心卖点：

1. 自动判断截图类型
2. 针对不同截图给不同分析
3. 不只是总结，还给下一步行动
4. 支持截图追问
5. 支持跨截图记忆和关联

---

# 1. 产品规划

## 1.1 产品定位

### 产品名称

AI Screenshot Assistant

### 新定位

一个能理解截图价值的 AI 信息助手。

### 用户价值

用户真正想要的不是“识别文字”，而是：

```text
这张截图讲了什么？
为什么重要？
我下一步该做什么？
它和我之前保存的内容有什么关系？
```

---

## 1.2 核心用户场景

| 场景 | 用户截图内容 | App 应该输出 |
|---|---|---|
| 技术报错 | Xcode / Terminal / Crash Log | 错误原因 + 修复建议 |
| 代码截图 | Swift / JS / Python 代码 | 代码解释 + 风险点 + 优化建议 |
| 聊天截图 | 微信 / Slack / iMessage | 结论 + 待办 + 对方意图 |
| 社交媒体 | Twitter/X / Reddit | 观点总结 + 背后逻辑 |
| 文档截图 | PDF / Docs / 网页文章 | TLDR + 关键概念 |
| UI 截图 | App 页面 / 设计稿 | UI 结构分析 + 优化建议 |
| 表格截图 | Excel / Notion Table | 数据解读 + 异常点 |
| 图表截图 | 折线图 / 柱状图 | 趋势分析 + 结论 |
| 邮件截图 | 客户邮件 / 工作邮件 | 重点 + 回复建议 |
| 学习资料 | 课程 / 论文 / 书籍 | 学习笔记 + Quiz |

---

## 1.3 功能优先级

### P0：必须实现

1. Screenshot Type Detection
2. Prompt Router
3. Specialized Result Card
4. Actionable Output
5. AI Chat with Screenshot Context

### P1：增强体验

1. Visual Understanding
2. Learning Mode
3. Debug Mode
4. UI Review Mode
5. Smart Suggestions

### P2：壁垒能力

1. Screenshot Memory
2. Cross Screenshot Linking
3. Knowledge Base
4. Auto Tagging
5. Personal Insight

---

# 2. 核心功能设计

## 2.1 Screenshot Type Detection

### 目标

上传截图后，AI 自动判断截图类型。

### 支持类型

```swift
enum ScreenshotType: String, Codable, CaseIterable {
    case chat
    case code
    case errorLog
    case socialPost
    case document
    case email
    case table
    case chart
    case uiDesign
    case videoSubtitle
    case learningMaterial
    case unknown
}
```

### 识别逻辑

先用本地规则快速判断，再用 AI 兜底。

```text
OCR 文本
+
图片视觉特征
+
关键词
+
布局特征
→ ScreenshotType
```

### 本地规则示例

| 类型 | 规则 |
|---|---|
| code | 包含 import / func / class / let / var / async |
| errorLog | 包含 error / exception / crash / stack trace |
| chat | 多行短句 + 时间 + 人名 |
| email | 包含 From / To / Subject / Regards |
| socialPost | 包含 like / repost / followers / @ |
| table | OCR 中出现大量数字、列名、金额 |
| chart | 图片中有坐标轴、百分比、趋势词 |
| uiDesign | 有按钮、Tab、Card、页面结构 |

---

## 2.2 Prompt Router

### 目标

不同截图类型使用不同 Prompt，不再一个 Prompt 处理所有图。

### 架构

```text
ScreenshotAnalyzer
├── OCRService
├── VisionAnalyzer
├── ScreenshotClassifier
├── PromptRouter
├── OpenAIService
└── ResultFormatter
```

### PromptRouter 示例

```swift
struct PromptRouter {
    func prompt(for type: ScreenshotType, ocrText: String, userLanguage: String = "zh-Hans") -> String {
        switch type {
        case .code:
            return PromptTemplates.codeAnalysis(ocrText)
        case .errorLog:
            return PromptTemplates.errorDebug(ocrText)
        case .chat:
            return PromptTemplates.chatSummary(ocrText)
        case .socialPost:
            return PromptTemplates.socialInsight(ocrText)
        case .email:
            return PromptTemplates.emailActionItems(ocrText)
        case .uiDesign:
            return PromptTemplates.uiReview(ocrText)
        case .table:
            return PromptTemplates.tableInsight(ocrText)
        case .chart:
            return PromptTemplates.chartInsight(ocrText)
        case .learningMaterial:
            return PromptTemplates.learningNotes(ocrText)
        default:
            return PromptTemplates.generalSummary(ocrText)
        }
    }
}
```

---

## 2.3 Specialized Result Card

### 目标

不同类型显示不同结果结构。

不要所有页面都显示：

```text
AI Summary
OCR Text
Copy
```

而是根据截图类型改变 UI。

### 通用 Result 结构

```swift
struct ScreenshotAnalysisResult: Codable, Identifiable {
    let id: UUID
    let type: ScreenshotType
    let title: String
    let summary: String
    let keyPoints: [String]
    let actionItems: [String]
    let insights: [String]
    let suggestedQuestions: [String]
    let tags: [String]
    let confidence: Double
    let createdAt: Date
}
```

---

# 3. 各截图类型的产品输出设计

## 3.1 技术报错截图：Debug Mode

### 用户价值

用户截 Xcode / Terminal / Crash Log 后，App 直接帮他定位问题。

### Result UI

```text
┌────────────────────────┐
│ 🐞 Debug Analysis       │
│ Confidence: 92%         │
├────────────────────────┤
│ Error Cause             │
│ MainActor isolation...  │
├────────────────────────┤
│ Fix Steps               │
│ 1. Add @MainActor       │
│ 2. Wrap UI update...    │
├────────────────────────┤
│ Copy Fix Prompt         │
│ Open in Cursor          │
└────────────────────────┘
```

### Prompt

```text
你是资深 iOS / Swift 调试专家。

请根据截图 OCR 文本分析：
1. 错误类型
2. 根本原因
3. 最可能出错的位置
4. 具体修复步骤
5. 可以复制到 Cursor 的修复 Prompt

输出 JSON：
{
  "title": "",
  "errorCause": "",
  "fixSteps": [],
  "cursorPrompt": "",
  "riskLevel": "low|medium|high",
  "confidence": 0.0
}

OCR:
{{ocr_text}}
```

### UI 组件

```text
DebugResultCard
├── ErrorCauseSection
├── FixStepsSection
├── CursorPromptCard
└── RiskBadge
```

---

## 3.2 代码截图：Code Insight Mode

### 输出

1. 代码作用
2. 核心逻辑
3. 潜在问题
4. 重构建议
5. 面试解释版本

### UI

```text
┌────────────────────────┐
│ 💻 Code Insight         │
├────────────────────────┤
│ What it does            │
├────────────────────────┤
│ Key Logic               │
├────────────────────────┤
│ Potential Issues        │
├────────────────────────┤
│ Improve with AI         │
└────────────────────────┘
```

### Prompt

```text
你是资深软件工程师。

请解释这段截图中的代码：
1. 它做了什么
2. 核心逻辑是什么
3. 有没有潜在 bug
4. 如何优化
5. 用适合面试回答的方式总结

OCR:
{{ocr_text}}
```

---

## 3.3 聊天截图：Conversation Intelligence

### 输出

1. 对话结论
2. 对方意图
3. 当前状态
4. 需要回复什么
5. 推荐回复模板

### UI

```text
┌────────────────────────┐
│ 💬 Conversation Summary │
├────────────────────────┤
│ Main Conclusion         │
├────────────────────────┤
│ Intent                  │
├────────────────────────┤
│ Next Reply              │
├────────────────────────┤
│ Copy Reply              │
└────────────────────────┘
```

### Prompt

```text
你是沟通分析助手。

请根据聊天截图 OCR 文本：
1. 总结对话结论
2. 判断对方意图
3. 提炼待办事项
4. 生成一条自然礼貌的回复
5. 标记是否需要立即跟进

OCR:
{{ocr_text}}
```

---

## 3.4 社交媒体截图：Insight Mode

### 输出

1. 核心观点
2. 背后逻辑
3. 值得收藏的原因
4. 可转成笔记的内容
5. 反方观点

### UI

```text
┌────────────────────────┐
│ 🧠 Social Insight       │
├────────────────────────┤
│ Core Idea               │
├────────────────────────┤
│ Why it matters          │
├────────────────────────┤
│ My Note                 │
├────────────────────────┤
│ Save to Knowledge Base  │
└────────────────────────┘
```

---

## 3.5 UI 设计截图：UI Review Mode

### 输出

1. 页面类型
2. 视觉层级
3. CTA 是否清晰
4. 信息密度
5. 可改进建议
6. SwiftUI 组件拆解

### Prompt

```text
你是高级 iOS 产品设计师和 SwiftUI 工程师。

请分析这个 UI 截图：
1. 页面类型
2. 信息架构
3. 视觉层级
4. 交互亮点
5. 问题和优化建议
6. SwiftUI 组件拆解建议

如果 OCR 不足，请结合视觉布局进行推断。
```

---

## 3.6 学习资料截图：Learning Mode

### 输出

1. 概念解释
2. 学习笔记
3. Quiz
4. Flashcards
5. 面试问答

### UI

```text
┌────────────────────────┐
│ 🎓 Learning Mode        │
├────────────────────────┤
│ Concept Summary         │
├────────────────────────┤
│ Flashcards              │
├────────────────────────┤
│ Quiz                    │
├────────────────────────┤
│ Interview Q&A           │
└────────────────────────┘
```

---

# 4. UI 细节设计

## 4.1 Result 页面升级

### 页面结构

```text
ResultView
├── Header
│   ├── BackButton
│   ├── TypeBadge
│   └── MoreButton
├── ScreenshotPreview
├── AIInsightHeader
│   ├── Icon
│   ├── DynamicTitle
│   └── ConfidenceBadge
├── SpecializedResultCard
├── ActionSuggestions
├── SuggestedQuestions
├── OCRTextCollapseCard
└── BottomActionBar
```

### TypeBadge 文案

| Type | Badge |
|---|---|
| code | Code |
| errorLog | Debug |
| chat | Chat |
| socialPost | Social |
| uiDesign | UI Review |
| learningMaterial | Learn |
| email | Email |
| table | Table |
| chart | Chart |

### 颜色建议

| Type | Color |
|---|---|
| Debug | #EF4444 |
| Code | #3B82F6 |
| Chat | #22C55E |
| Social | #8B5CF6 |
| UI Review | #F97316 |
| Learning | #06B6D4 |
| Email | #6366F1 |
| Table | #10B981 |
| Chart | #F59E0B |

---

## 4.2 Result 页面 Wireframe

```text
┌────────────────────────────┐
│ ← Result        [Debug] ⋯  │
├────────────────────────────┤
│ ┌────────────────────────┐ │
│ │ Screenshot Preview     │ │
│ └────────────────────────┘ │
│                            │
│ 🐞 Debug Analysis    92%   │
│ ┌────────────────────────┐ │
│ │ Error Cause            │ │
│ │ MainActor isolation... │ │
│ └────────────────────────┘ │
│                            │
│ ┌────────────────────────┐ │
│ │ Fix Steps              │ │
│ │ 1. Add @MainActor      │ │
│ │ 2. Use Task {...}      │ │
│ └────────────────────────┘ │
│                            │
│ Try next:                  │
│ [Explain] [Fix Prompt]     │
│ [Open Chat]                │
│                            │
│ [Copy All] [Ask AI]        │
└────────────────────────────┘
```

---

## 4.3 Home 页面升级

### 新增入口

```text
HomeView
├── UploadHeroCard
├── Smart Modes
│   ├── Debug
│   ├── Code
│   ├── Chat
│   └── Learn
├── Recent Intelligence
└── Knowledge Highlights
```

### Home Wireframe

```text
┌────────────────────────────┐
│ AI Screenshot       ⚙️      │
├────────────────────────────┤
│ Upload screenshot           │
│ [ Upload Image ]            │
│                            │
│ Smart Modes                 │
│ [Debug] [Code] [Chat]       │
│ [Learn] [UI Review]         │
│                            │
│ Recent Intelligence         │
│ 🐞 Fixed Swift Error        │
│ 🧠 Agent Trend Note         │
│ 🎓 SwiftUI Learning Card    │
└────────────────────────────┘
```

---

## 4.4 Chat 页面升级

### Chat with Context

```text
┌────────────────────────────┐
│ Chat with Screenshot        │
├────────────────────────────┤
│ Screenshot + Type Badge     │
│ Summary Preview             │
├────────────────────────────┤
│ AI: 这张图主要讲...          │
│ User: 帮我生成修复 Prompt    │
│ AI: 可以复制下面内容...      │
│                            │
│ [Ask anything...]     Send  │
└────────────────────────────┘
```

### Suggested Questions

每种类型不同：

| Type | Questions |
|---|---|
| Debug | 为什么报错？/ 如何修复？/ 生成 Cursor Prompt |
| Code | 解释逻辑 / 优化代码 / 面试怎么讲 |
| Chat | 帮我回复 / 对方什么意思 / 提炼待办 |
| Social | 反方观点 / 转成笔记 / 生成金句 |
| Learning | 出题测试 / 生成卡片 / 用例子解释 |

---

# 5. 技术架构

## 5.1 总体架构

```text
ImageInput
 ↓
ImagePreprocessor
 ↓
OCRService
 ↓
VisionAnalyzer
 ↓
ScreenshotClassifier
 ↓
PromptRouter
 ↓
OpenAIStreamingService
 ↓
ResultParser
 ↓
SwiftUI ViewModel
 ↓
Specialized UI
```

---

## 5.2 Services

```text
Services/
├── Image/
│   ├── ImageInputService.swift
│   ├── ImagePreprocessor.swift
│   └── ImageCompressionService.swift
├── OCR/
│   └── OCRService.swift
├── Vision/
│   └── VisionAnalyzer.swift
├── Classification/
│   ├── ScreenshotClassifier.swift
│   └── ClassificationRuleEngine.swift
├── AI/
│   ├── OpenAIStreamingService.swift
│   ├── PromptRouter.swift
│   ├── PromptTemplates.swift
│   └── ResultParser.swift
├── Memory/
│   ├── ScreenshotMemoryStore.swift
│   └── TaggingService.swift
└── Persistence/
    └── ScreenshotRepository.swift
```

---

## 5.3 Features

```text
Features/
├── Home/
│   ├── HomeView.swift
│   └── HomeViewModel.swift
├── Result/
│   ├── ResultView.swift
│   ├── ResultViewModel.swift
│   └── Cards/
│       ├── DebugResultCard.swift
│       ├── CodeInsightCard.swift
│       ├── ChatSummaryCard.swift
│       ├── SocialInsightCard.swift
│       ├── UIReviewCard.swift
│       └── LearningCard.swift
├── Chat/
│   ├── ChatView.swift
│   ├── ChatViewModel.swift
│   └── Components/
└── History/
```

---

# 6. 数据模型

## 6.1 ScreenshotItem

```swift
struct ScreenshotItem: Identifiable, Codable {
    let id: UUID
    var imageLocalPath: String
    var ocrText: String
    var type: ScreenshotType
    var result: ScreenshotAnalysisResult
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
}
```

---

## 6.2 ScreenshotAnalysisResult

```swift
struct ScreenshotAnalysisResult: Identifiable, Codable {
    let id: UUID
    var type: ScreenshotType
    var title: String
    var summary: String
    var keyPoints: [String]
    var actionItems: [String]
    var insights: [String]
    var suggestedQuestions: [String]
    var confidence: Double
    var rawJSON: String?
}
```

---

## 6.3 ChatMessage

```swift
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var role: ChatRole
    var content: String
    var createdAt: Date
}

enum ChatRole: String, Codable {
    case system
    case user
    case assistant
}
```

---

# 7. 代码实现细节

## 7.1 ScreenshotClassifier

```swift
final class ScreenshotClassifier {
    private let ruleEngine = ClassificationRuleEngine()

    func classify(ocrText: String, visionHints: VisionHints) async -> ScreenshotType {
        if let localType = ruleEngine.match(ocrText: ocrText, visionHints: visionHints) {
            return localType
        }

        return await classifyWithAI(ocrText: ocrText, visionHints: visionHints)
    }

    private func classifyWithAI(ocrText: String, visionHints: VisionHints) async -> ScreenshotType {
        // Use OpenAI lightweight model or local fallback.
        // Must return one of ScreenshotType.
        return .unknown
    }
}
```

---

## 7.2 ClassificationRuleEngine

```swift
struct ClassificationRuleEngine {
    func match(ocrText: String, visionHints: VisionHints) -> ScreenshotType? {
        let text = ocrText.lowercased()

        if containsAny(text, ["fatal error", "exception", "stack trace", "crash", "traceback"]) {
            return .errorLog
        }

        if containsAny(text, ["import ", "func ", "class ", "struct ", "let ", "var "]) {
            return .code
        }

        if containsAny(text, ["from:", "to:", "subject:", "regards"]) {
            return .email
        }

        if containsAny(text, ["like", "repost", "followers", "@"]) {
            return .socialPost
        }

        if visionHints.hasTableLikeLayout {
            return .table
        }

        if visionHints.hasChartLikeLayout {
            return .chart
        }

        if visionHints.hasUIControls {
            return .uiDesign
        }

        return nil
    }

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
```

---

## 7.3 VisionHints

```swift
struct VisionHints: Codable {
    var hasTableLikeLayout: Bool
    var hasChartLikeLayout: Bool
    var hasUIControls: Bool
    var textBlockCount: Int
    var averageTextLineLength: Double
    var detectedLanguages: [String]
}
```

---

## 7.4 PromptTemplates

```swift
enum PromptTemplates {
    static func generalSummary(_ text: String) -> String {
        """
        你是专业截图总结助手。
        请总结以下 OCR 文本，输出中文：
        1. 核心摘要
        2. 关键点
        3. 下一步建议

        OCR:
        \(text)
        """
    }

    static func errorDebug(_ text: String) -> String {
        """
        你是资深软件调试专家。
        请分析错误截图 OCR，输出 JSON：
        {
          "title": "",
          "summary": "",
          "keyPoints": [],
          "actionItems": [],
          "insights": [],
          "suggestedQuestions": [],
          "confidence": 0.0
        }

        OCR:
        \(text)
        """
    }

    static func chatSummary(_ text: String) -> String {
        """
        你是沟通分析助手。
        请根据聊天截图 OCR：
        1. 总结对话结论
        2. 判断对方意图
        3. 提炼待办
        4. 生成建议回复

        OCR:
        \(text)
        """
    }
}
```

---

## 7.5 ResultViewModel

```swift
@MainActor
final class ResultViewModel: ObservableObject {
    @Published var phase: AnalysisPhase = .idle
    @Published var ocrText: String = ""
    @Published var type: ScreenshotType = .unknown
    @Published var streamingText: String = ""
    @Published var result: ScreenshotAnalysisResult?

    private let ocrService: OCRService
    private let classifier: ScreenshotClassifier
    private let promptRouter: PromptRouter
    private let openAIService: OpenAIStreamingService

    func analyze(image: UIImage) async {
        phase = .ocr
        ocrText = await ocrService.recognizeText(from: image)

        phase = .classifying
        let hints = VisionHints(
            hasTableLikeLayout: false,
            hasChartLikeLayout: false,
            hasUIControls: false,
            textBlockCount: 0,
            averageTextLineLength: 0,
            detectedLanguages: []
        )

        type = await classifier.classify(ocrText: ocrText, visionHints: hints)

        phase = .thinking
        let prompt = promptRouter.prompt(for: type, ocrText: ocrText)

        phase = .streaming
        do {
            for try await token in openAIService.stream(prompt: prompt) {
                streamingText += token
            }

            phase = .completed
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
```

---

# 8. Codex 实现规则

把下面内容放进项目根目录：

```text
CODEX_RULES.md
```

## 8.1 总体规则

```text
You are working on a SwiftUI iOS app named AI Screenshot Assistant.

Goal:
Upgrade the app from simple OCR summary to AI Screenshot Intelligence.

Always follow:
1. Use SwiftUI.
2. Use MVVM.
3. Keep each feature in Features/{FeatureName}.
4. Keep services in Services/{Domain}.
5. Do not put networking code inside Views.
6. Do not put business logic inside SwiftUI Views.
7. All AI prompts must be defined in PromptTemplates.swift.
8. Screenshot type routing must go through PromptRouter.swift.
9. Result UI must be rendered by ScreenshotType.
10. Use async/await for all async operations.
11. Use @MainActor for ViewModels.
12. Do not hardcode API keys.
13. Store OpenAI key in Config or Keychain.
14. All user-visible strings should be easy to localize.
```

## 8.2 Feature 规则

```text
When implementing a new screenshot type:
1. Add enum case in ScreenshotType.
2. Add classification rule in ClassificationRuleEngine.
3. Add prompt in PromptTemplates.
4. Add route in PromptRouter.
5. Add specialized result card in Features/Result/Cards.
6. Add suggested questions in SuggestedQuestionProvider.
7. Add color and icon mapping in ScreenshotTypeStyle.
```

## 8.3 UI 规则

```text
UI Design Rules:
1. Use Apple Intelligence inspired style.
2. Use rounded cards with corner radius 20-28.
3. Use soft shadows.
4. Use type-specific badge color.
5. Result page must always show:
   - Screenshot preview
   - Type badge
   - AI result card
   - Suggested questions
   - OCR collapsed text
   - Copy / Ask AI actions
6. Streaming output must show cursor blinking.
7. Empty states must be friendly and actionable.
```

## 8.4 AI 规则

```text
AI Rules:
1. Never use one generic prompt for all screenshot types.
2. Always classify screenshot type first.
3. Use PromptRouter to select prompt.
4. Ask OpenAI to return structured JSON when possible.
5. If JSON parsing fails, fallback to raw markdown rendering.
6. Always provide:
   - summary
   - keyPoints
   - actionItems
   - suggestedQuestions
7. Do not invent facts not visible in OCR or image.
8. If confidence is low, say so.
```

---

# 9. Codex 任务拆解

## Task 1：新增 ScreenshotType

```text
Create Models/ScreenshotType.swift.
Add enum ScreenshotType with cases:
chat, code, errorLog, socialPost, document, email, table, chart, uiDesign, videoSubtitle, learningMaterial, unknown.
Add displayName, iconName, tintColorName computed properties.
```

## Task 2：新增 ScreenshotClassifier

```text
Create Services/Classification/ScreenshotClassifier.swift.
Create ClassificationRuleEngine.swift.
Implement local rule-based classification by OCR keywords and VisionHints.
Fallback to unknown.
```

## Task 3：新增 PromptRouter

```text
Create Services/AI/PromptRouter.swift.
Route ScreenshotType to PromptTemplates.
Every type must have a separate prompt.
```

## Task 4：升级 Result UI

```text
Update ResultView:
- Show type badge
- Show dynamic title
- Render specialized card based on ScreenshotType
- Show suggested questions
- Collapse OCR text by default
```

## Task 5：新增 Specialized Cards

```text
Create:
- DebugResultCard
- CodeInsightCard
- ChatSummaryCard
- SocialInsightCard
- UIReviewCard
- LearningCard

Each card accepts ScreenshotAnalysisResult.
```

## Task 6：新增 AI Chat Suggestions

```text
Create SuggestedQuestionProvider.swift.
Return type-specific questions.
Display chips under AI result.
Tap chip opens ChatView with prefilled question.
```

## Task 7：新增 Memory 基础

```text
Create ScreenshotMemoryStore.swift.
Save ScreenshotItem:
- OCR text
- type
- result
- tags
- createdAt
```

---

# 10. 最小可落地版本 MVP

如果你想最快做出特色，只做这 4 件：

```text
1. ScreenshotTypeDetection
2. PromptRouter
3. Type-specific Result Card
4. Suggested Questions
```

这 4 个做好，用户会立刻感觉：

```text
这个 App 不是 OCR，而是真的懂我的截图。
```

---

# 11. 开发验收标准

## 功能验收

- 上传代码截图，识别为 Code
- 上传报错截图，识别为 Debug
- 上传聊天截图，识别为 Chat
- 不同类型使用不同 UI
- 不同类型出现不同建议问题
- AI 输出包含下一步行动
- OCR 文本默认折叠
- 可以从 Result 进入 Chat

## 质量验收

- View 中没有网络逻辑
- Prompt 不写在 ViewModel
- 所有 ScreenshotType 有 icon/color/title
- JSON 解析失败有 fallback
- API Key 没有硬编码

---

# 12. 后续增强方向

## 12.1 Screenshot Memory

让 App 记住用户截图内容。

能力：

```text
这个截图和你昨天保存的 MCP 内容相关。
```

## 12.2 Knowledge Base

按主题自动聚类：

- iOS
- AI Agent
- SwiftUI
- Product Design
- Job Search

## 12.3 Auto Learning Pack

对学习资料自动生成：

- Flashcards
- Quiz
- Interview Q&A

## 12.4 Cross Screenshot Summary

选择多张截图：

```text
帮我总结这 5 张图共同讲了什么。
```

---

