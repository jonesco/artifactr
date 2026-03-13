import SwiftData
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@Model
final class Entry {
    var uuid: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var isFavorite: Bool = false
    var categoryNames: [String] = []
    var tags: [String] = []
    var createdAt: Date = Date()
    var images: [Data] = []

    init(
        title: String = "",
        content: String = "",
        isFavorite: Bool = false,
        categoryNames: [String] = [],
        tags: [String] = [],
        images: [Data] = []
    ) {
        self.uuid = UUID()
        self.title = title
        self.content = content
        self.isFavorite = isFavorite
        self.categoryNames = categoryNames
        self.tags = tags
        self.createdAt = Date()
        self.images = images
    }
}

// MARK: - Transferable (single-artifact export/share)

extension Entry: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { entry in
            let iso = ISO8601DateFormatter()
            let backup = ArtifactrBackup(
                version: 2,
                exportedAt: iso.string(from: Date()),
                entries: [EntryBackup(
                    id: entry.uuid.uuidString,
                    title: entry.title,
                    content: entry.content,
                    isFavorite: entry.isFavorite,
                    categoryNames: entry.categoryNames,
                    tags: entry.tags,
                    createdAt: iso.string(from: entry.createdAt)
                )],
                categories: []
            )
            let data = try JSONEncoder().encode(backup)
            let safe = entry.title.isEmpty ? "artifact" : entry.title.replacingOccurrences(of: "/", with: "-")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safe).json")
            try data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}
