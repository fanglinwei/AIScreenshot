import Foundation

struct SharedImportItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let title: String
    let ocrText: String
    let summary: String
    let mode: SummaryMode
    let imageFilename: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        ocrText: String,
        summary: String,
        mode: SummaryMode = .summary,
        imageFilename: String?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.ocrText = ocrText
        self.summary = summary
        self.mode = mode
        self.imageFilename = imageFilename
    }
}
