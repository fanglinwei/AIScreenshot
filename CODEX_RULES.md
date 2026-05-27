
## 总体规则

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

## Feature 规则

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

## UI 规则

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

## AI 规则

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