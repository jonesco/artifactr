import Foundation

struct EntryBackup: Codable {
    let id: String
    let title: String
    let content: String
    let isFavorite: Bool
    let categoryNames: [String]
    let tags: [String]
    let createdAt: String
}

struct CategoryBackup: Codable {
    let name: String
    let icon: String
}

struct ArtifactrBackup: Codable {
    let version: Int
    let exportedAt: String
    let entries: [EntryBackup]
    let categories: [CategoryBackup]
}
