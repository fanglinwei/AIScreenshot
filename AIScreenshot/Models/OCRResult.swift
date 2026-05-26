import Foundation

struct OCRResult: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var title: String
    var ocrText: String
    var summary: String
    var mode: SummaryMode
    var imageFilename: String?

    init(id: UUID = UUID(), createdAt: Date = Date(), title: String, ocrText: String, summary: String, mode: SummaryMode, imageFilename: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.ocrText = ocrText
        self.summary = summary
        self.mode = mode
        self.imageFilename = imageFilename
    }
}
