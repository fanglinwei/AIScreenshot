import Foundation

enum ShareSummaryMode: String, Codable {
    case summary = "摘要"
}

struct ShareImportItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let ocrText: String
    let summary: String
    let mode: ShareSummaryMode
    let imageFilename: String?
}
