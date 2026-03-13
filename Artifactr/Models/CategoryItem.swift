import SwiftData
import Foundation

@Model
final class CategoryItem {
    var name: String = ""
    var icon: String = "folder"   // SF Symbol name
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(name: String = "", icon: String = "folder", sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    static func suggestedIcons(for name: String) -> [String] {
        let words = name.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        var results: [String] = []
        for word in words {
            if let symbol = keywordIconMap[word], !seen.contains(symbol) {
                seen.insert(symbol)
                results.append(symbol)
            }
        }
        return Array(results.prefix(5))
    }

    private static let keywordIconMap: [String: String] = [
        // Food & Cooking
        "recipe": "fork.knife", "recipes": "fork.knife",
        "food": "fork.knife", "cook": "fork.knife", "cooking": "fork.knife",
        "meal": "fork.knife", "meals": "fork.knife", "dinner": "fork.knife",
        "lunch": "fork.knife", "breakfast": "fork.knife", "kitchen": "fork.knife",
        "eat": "fork.knife", "eating": "fork.knife", "bake": "fork.knife", "baking": "fork.knife",
        "drink": "cup.and.saucer", "drinks": "cup.and.saucer",
        "coffee": "cup.and.saucer", "tea": "cup.and.saucer", "smoothie": "cup.and.saucer",
        "nutrition": "carrot", "diet": "carrot", "vegetable": "carrot", "vegetables": "carrot",

        // Home & DIY
        "home": "house", "house": "house", "apartment": "house",
        "diy": "hammer", "build": "hammer", "woodwork": "hammer", "craft": "hammer",
        "repair": "wrench.and.screwdriver", "fix": "wrench.and.screwdriver", "maintenance": "wrench.and.screwdriver",

        // Health & Fitness
        "health": "heart.text.square", "wellness": "heart.text.square",
        "medical": "cross.case", "medicine": "cross.case", "doctor": "cross.case",
        "fitness": "figure.walk", "workout": "figure.walk", "exercise": "figure.walk",
        "gym": "figure.walk", "run": "figure.walk", "running": "figure.walk",
        "walk": "figure.walk", "walking": "figure.walk", "yoga": "figure.walk",

        // Work & Finance
        "work": "briefcase", "job": "briefcase", "career": "briefcase",
        "finance": "dollarsign.circle", "money": "dollarsign.circle", "budget": "dollarsign.circle",
        "invest": "chart.line.uptrend.xyaxis", "investing": "chart.line.uptrend.xyaxis", "stocks": "chart.line.uptrend.xyaxis",
        "analytics": "chart.bar", "data": "chart.bar", "stats": "chart.bar", "metrics": "chart.bar",
        "business": "chart.bar",

        // Learning & Reference
        "book": "book", "books": "book", "read": "book", "reading": "book",
        "learn": "graduationcap", "learning": "graduationcap", "study": "graduationcap", "school": "graduationcap",
        "research": "magnifyingglass",
        "news": "newspaper", "articles": "newspaper", "article": "newspaper",

        // Creative
        "write": "pencil", "writing": "pencil", "journal": "pencil", "notes": "pencil", "note": "pencil",
        "art": "paintbrush", "draw": "paintbrush", "drawing": "paintbrush", "design": "paintbrush", "sketch": "paintbrush",
        "music": "music.note", "song": "music.note", "songs": "music.note", "playlist": "music.note",
        "photo": "camera", "photos": "camera", "picture": "camera", "pictures": "camera",
        "film": "film", "movie": "film", "movies": "film", "tv": "film", "show": "film", "series": "film",

        // Tech & AI
        "tech": "cpu", "technology": "cpu", "hardware": "cpu",
        "code": "terminal", "coding": "terminal", "programming": "terminal", "dev": "terminal", "software": "terminal",
        "ai": "wand.and.stars", "gpt": "wand.and.stars", "claude": "wand.and.stars",
        "prompt": "wand.and.stars", "prompts": "wand.and.stars", "llm": "wand.and.stars",
        "idea": "brain.head.profile", "ideas": "brain.head.profile", "brainstorm": "brain.head.profile",

        // Nature & Travel
        "nature": "leaf", "plant": "leaf", "plants": "leaf", "garden": "leaf", "gardening": "leaf",
        "outdoor": "sun.max", "outdoors": "sun.max", "hike": "sun.max", "hiking": "sun.max",
        "camp": "sun.max", "camping": "sun.max",
        "travel": "airplane", "trip": "airplane", "vacation": "airplane", "flight": "airplane",
        "map": "map", "maps": "map", "location": "map",

        // Social & Communication
        "people": "person.2", "family": "person.2", "friend": "person.2", "friends": "person.2",
        "chat": "message", "conversation": "message",
        "web": "globe", "internet": "globe",

        // Lifestyle
        "shop": "cart", "shopping": "cart", "buy": "cart",
        "gift": "gift", "gifts": "gift",
        "game": "gamecontroller", "games": "gamecontroller", "gaming": "gamecontroller",
        "hobby": "puzzlepiece", "hobbies": "puzzlepiece",

        // Misc
        "favorite": "star", "favorites": "star", "best": "star", "top": "star",
        "love": "heart",
        "hot": "flame", "trending": "flame",
        "inspire": "lightbulb", "inspiration": "lightbulb",
    ]

    static let availableIcons: [(symbol: String, label: String)] = [
        // Organization
        ("folder",                          "Folder"),
        ("bookmark",                        "Bookmark"),
        ("tag",                             "Tag"),
        ("list.bullet",                     "List"),
        ("calendar",                        "Calendar"),
        ("clock",                           "Time"),

        // Food & Home
        ("fork.knife",                      "Recipes"),
        ("cup.and.saucer",                  "Drinks"),
        ("carrot",                          "Nutrition"),
        ("house",                           "Home"),
        ("hammer",                          "DIY"),
        ("wrench.and.screwdriver",          "Repair"),

        // Health & Fitness
        ("heart.text.square",              "Health"),
        ("figure.walk",                     "Fitness"),
        ("cross.case",                      "Medical"),

        // Work & Finance
        ("briefcase",                       "Work"),
        ("dollarsign.circle",               "Finance"),
        ("chart.bar",                       "Business"),
        ("chart.line.uptrend.xyaxis",       "Analytics"),

        // Learning & Reference
        ("book",                            "Books"),
        ("graduationcap",                   "Learning"),
        ("magnifyingglass",                 "Research"),
        ("newspaper",                       "News"),

        // Creative
        ("pencil",                          "Writing"),
        ("paintbrush",                      "Art"),
        ("music.note",                      "Music"),
        ("camera",                          "Photography"),
        ("film",                            "Film & TV"),

        // Tech & AI
        ("cpu",                             "Tech"),
        ("terminal",                        "Code"),
        ("wand.and.stars",                  "AI"),
        ("brain.head.profile",              "Ideas"),
        ("sparkles",                        "Highlights"),

        // Nature & Travel
        ("leaf",                            "Nature"),
        ("sun.max",                         "Outdoors"),
        ("airplane",                        "Travel"),
        ("map",                             "Maps"),

        // Social & Communication
        ("person.2",                        "People"),
        ("message",                         "Chat"),
        ("globe",                           "Web"),

        // Lifestyle
        ("cart",                            "Shopping"),
        ("gift",                            "Gifts"),
        ("gamecontroller",                  "Gaming"),
        ("puzzlepiece",                     "Hobbies"),

        // Misc
        ("star",                            "Star"),
        ("heart",                           "Favorites"),
        ("flame",                           "Trending"),
        ("lightbulb",                       "Inspiration"),
    ]
}
