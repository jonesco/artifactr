import SwiftUI
import SwiftData

struct EntriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Entry.createdAt, order: .reverse) private var allEntries: [Entry]
    @Query(sort: \CategoryItem.name) private var categories: [CategoryItem]

    let filter: SidebarSelection
    let searchText: String

    @State private var showNewEntry = false
    @State private var editingEntry: Entry?
    @State private var entryToDelete: Entry?
    @State private var readingEntry: Entry?

    var filteredEntries: [Entry] {
        allEntries.filter { entry in
            let matchesFilter: Bool = switch filter {
            case .all:              true
            case .favorites:        entry.isFavorite
            case .category(let n):  entry.categoryNames.contains(n)
            }

            let matchesSearch: Bool = searchText.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })

            return matchesFilter && matchesSearch
        }
    }

    var filterTitle: String {
        switch filter {
        case .all:              return "All Artifacts"
        case .favorites:        return "Favorites"
        case .category(let n):  return n
        }
    }

    var body: some View {
        Group {
            if filteredEntries.isEmpty {
                emptyStateView
            } else {
                entryGrid
            }
        }
        .navigationTitle(filterTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewEntry = true
                } label: {
                    Label("New Artifact", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showNewEntry) {
            EntryFormView(entry: nil, preselectedCategory: {
                if case .category(let name) = filter { return name as String? }
                return nil
            }())
        }
        .fullScreenCover(item: $editingEntry) { entry in
            EntryFormView(entry: entry)
        }
        .fullScreenCover(item: $readingEntry) { entry in
            EntryDetailView(entry: entry)
        }
        #else
        .sheet(isPresented: $showNewEntry) {
            EntryFormView(entry: nil, preselectedCategory: {
                if case .category(let name) = filter { return name as String? }
                return nil
            }())
            .frame(minWidth: 620, minHeight: 700)
        }
        .sheet(item: $editingEntry) { entry in
            EntryFormView(entry: entry)
                .frame(minWidth: 620, minHeight: 700)
        }
        #endif
        .confirmationDialog(
            "Delete this artifact?",
            isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Artifact", role: .destructive) {
                if let e = entryToDelete {
                    modelContext.delete(e)
                    entryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        }
    }

    @ViewBuilder
    var emptyStateView: some View {
        ContentUnavailableView {
            Label(
                searchText.isEmpty ? "No Artifacts" : "No Results",
                systemImage: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass"
            )
        } description: {
            if searchText.isEmpty {
                switch filter {
                case .all:
                    Text("Tap + to create your first artifact.")
                case .favorites:
                    Text("Star an artifact to add it to Favorites.")
                case .category(let name):
                    Text("No artifacts in \"\(name)\" yet.")
                }
            } else {
                Text("Try a different search term.")
            }
        } actions: {
            if searchText.isEmpty, case .all = filter {
                Button("New Artifact") { showNewEntry = true }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.black)
            }
        }
    }

    @ViewBuilder
    var entryGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredEntries) { entry in
                    EntryCardView(
                        entry: entry,
                        categories: categories,
                        onEdit: { editingEntry = entry },
                        onDelete: { entryToDelete = entry },
                        onOpen: { readingEntry = entry }
                    )
                }
            }
            .padding()
        }
        #if os(iOS)
        .scrollContentBackground(.hidden)
        .contentMargins(
            .bottom,
            UIDevice.current.userInterfaceIdiom == .phone ? 80 : 0,
            for: .scrollContent
        )
        #endif
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 300, maximum: 420))]
    }
}

