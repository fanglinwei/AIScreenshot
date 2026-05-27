# AI Screenshot Assistant

SwiftUI MVP for an AI OCR + summary iOS app.

## Features
- Home upload screen with `PhotosPicker`
- Vision OCR using `VNRecognizeTextRequest`
- Multi-provider AI summary service with OpenAI, DeepSeek, Qwen, Kimi, Xiaomi MiMo, custom OpenAI-compatible endpoints, and local free fallback
- Result screen with OCR text, AI summary, copy action
- History screen with local persistence via `UserDefaults`
- Settings screen with provider switch, API key input, model selection, auto-copy option
- Design System tokens matching the high-fidelity mockup

## Setup
1. Create a new iOS App project in Xcode named `AIScreenshotAssistant`.
2. Delete the generated `ContentView.swift` and app entry file.
3. Drag all folders in this package into the Xcode project.
4. Set deployment target to iOS 17+.
5. Run on device or simulator.
6. Open Settings in the app, choose a provider, then paste the matching API key.
7. Choose Local Free if you want OCR-based summary without any API key.
8. Custom provider accepts any OpenAI-compatible `/chat/completions` endpoint.

## Privacy
Add this to `Info.plist` if Xcode asks for photo access copy:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Select screenshots to extract text and summarize.</string>
```

`PhotosPicker` usually avoids full library permission prompts because the user explicitly picks items.
