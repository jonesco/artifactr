import SwiftUI

/// Curated system tints that remain accessible in both light and dark appearances.
enum AccentChoice: String, CaseIterable, Identifiable, Codable {
    case blue
    case indigo
    case orange
    case pink
    case purple

    var id: String { rawValue }

    var color: Color {
        #if os(iOS)
        switch self {
        case .blue: return Color(UIColor.systemBlue)
        case .indigo: return Color(UIColor.systemIndigo)
        case .orange: return Color(UIColor.systemOrange)
        case .pink: return Color(UIColor.systemPink)
        case .purple: return Color(UIColor.systemPurple)
        }
        #elseif os(macOS)
        switch self {
        case .blue: return Color(NSColor.systemBlue)
        case .indigo: return Color(NSColor.systemIndigo)
        case .orange: return Color(NSColor.systemOrange)
        case .pink: return Color(NSColor.systemPink)
        case .purple: return Color(NSColor.systemPurple)
        }
        #else
        Color.blue
        #endif
    }

    static func from(raw: String) -> AccentChoice {
        AccentChoice(rawValue: raw) ?? .blue
    }
}
