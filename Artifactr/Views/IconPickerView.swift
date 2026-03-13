import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    var suggestions: [String] = []

    private let columns = [GridItem(.adaptive(minimum: 56))]

    private var suggestedItems: [(symbol: String, label: String)] {
        suggestions.compactMap { symbol in
            CategoryItem.availableIcons.first(where: { $0.symbol == symbol })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !suggestedItems.isEmpty {
                Text("Suggested")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(suggestedItems, id: \.symbol) { item in
                        iconButton(item)
                    }
                }

                Divider()
                    .padding(.vertical, 12)

                Text("All Icons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CategoryItem.availableIcons, id: \.symbol) { item in
                    iconButton(item)
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func iconButton(_ item: (symbol: String, label: String)) -> some View {
        Button {
            selectedIcon = item.symbol
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.symbol)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(
                        selectedIcon == item.symbol
                            ? AnyShapeStyle(.tint)
                            : AnyShapeStyle(Color.secondary.opacity(0.12))
                    )
                    .foregroundStyle(
                        selectedIcon == item.symbol ? Color.white : Color.primary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .animation(.easeInOut(duration: 0.15), value: selectedIcon)

                Text(item.label)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

