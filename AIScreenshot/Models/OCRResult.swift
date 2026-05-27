import Foundation

struct OCRResult: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var createdAt: Date
    var title: String
    var imagePath: String?
    var ocrText: String
    var summary: String
    var screenshotType: ScreenshotType
    var tags: [String]
    var mode: SummaryMode
    var imageFilename: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        imagePath: String? = nil,
        ocrText: String,
        summary: String,
        mode: SummaryMode,
        screenshotType: ScreenshotType = .unknown,
        tags: [String] = [],
        imageFilename: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.imagePath = imagePath
        self.ocrText = ocrText
        self.summary = summary
        self.screenshotType = screenshotType
        self.tags = tags
        self.mode = mode
        self.imageFilename = imageFilename
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case title
        case imagePath
        case ocrText
        case summary
        case screenshotType
        case tags
        case mode
        case imageFilename
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        title = try container.decode(String.self, forKey: .title)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        ocrText = try container.decode(String.self, forKey: .ocrText)
        summary = try container.decode(String.self, forKey: .summary)
        screenshotType = try container.decodeIfPresent(ScreenshotType.self, forKey: .screenshotType) ?? .unknown
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        mode = try container.decode(SummaryMode.self, forKey: .mode)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
    }
}
