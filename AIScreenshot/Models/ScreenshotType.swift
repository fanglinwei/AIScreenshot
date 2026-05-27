import Foundation

enum ScreenshotType: String, Codable, CaseIterable, Equatable, Hashable {
    case chat
    case code
    case social
    case pdf
    case email
    case table
    case chart
    case ui
    case document
    case unknown

    var displayName: String {
        switch self {
        case .chat:
            return "聊天"
        case .code:
            return "代码"
        case .social:
            return "社交"
        case .pdf:
            return "PDF"
        case .email:
            return "邮件"
        case .table:
            return "表格"
        case .chart:
            return "图表"
        case .ui:
            return "界面"
        case .document:
            return "文档"
        case .unknown:
            return "未知"
        }
    }

    var systemImage: String {
        switch self {
        case .chat:
            return "message.fill"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .social:
            return "at"
        case .pdf:
            return "doc.richtext.fill"
        case .email:
            return "envelope.fill"
        case .table:
            return "tablecells.fill"
        case .chart:
            return "chart.xyaxis.line"
        case .ui:
            return "rectangle.inset.filled"
        case .document:
            return "doc.text.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}
