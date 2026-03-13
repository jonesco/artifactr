import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CategoryItem.sortOrder), SortDescriptor(\CategoryItem.createdAt)]) private var categories: [CategoryItem]
    @Query private var entries: [Entry]

    @Binding var selection: SidebarSelection
    /// Called when the user picks a filter item — used on iPhone to close the sidebar sheet.
    /// No-op when not in a sheet context (iPad/Mac split view).
    var onSelect: (() -> Void)? = nil
    /// Called when the search icon is tapped; triggers navigation to All Artifacts with search active.
    var onSearchActivate: (() -> Void)? = nil
    let onBackupTapped: () -> Void

    @State private var showNewEntry = false
    @State private var showNewCategory = false
    @State private var editingCategory: CategoryItem?
    @State private var categoryToDelete: CategoryItem?
    @State private var isEditing = false
    @State private var draggingCategory: CategoryItem?

    var body: some View {
        listView
            #if os(iOS)
            .navigationBarHidden(true)
            #else
            .navigationTitle("Artifactr")
            .toolbar { toolbarContent }
            #endif
            #if os(macOS)
            .sheet(isPresented: $showNewEntry, onDismiss: { onSelect?() }) {
                EntryFormView(entry: nil)
                    .frame(minWidth: 620, minHeight: 700)
            }
            #endif
            .sheet(isPresented: $showNewCategory) {
                CategoryFormView(category: nil, nextSortOrder: categories.count)
            }
            .sheet(item: $editingCategory) { cat in
                CategoryFormView(category: cat)
            }
            .overlay(alignment: .center) {
                if let pending = categoryToDelete {
                    DeleteCategoryOverlay(
                        name: pending.name,
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                deleteCategory(pending)
                            }
                        },
                        onCancel: { categoryToDelete = nil }
                    )
                    .transition(.opacity.combined(with: .scale))
                    .ignoresSafeArea()
                }
            }
    }

    // MARK: - List

    @ViewBuilder
    private var listView: some View {
        #if os(macOS)
        List(selection: $selection) {
            staticSection
            categoriesSection
        }
        #else
        List {
            Section {
                HStack(alignment: .center) {
                    Image("ArtifactrLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    Spacer()
                    Button { onSearchActivate?() } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 20))
            }
            staticSection
            categoriesSection
        }
        .contentMargins(.top, -8, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        #endif
    }

    // MARK: - Sections

    private var staticSection: some View {
        Section {
            navRow("All Artifacts", icon: "tray.full", value: .all)
            navRow("Favorites", icon: "star.fill", value: .favorites)
        }
    }

    private var categoriesSection: some View {
        #if os(iOS)
        Section {
            HStack {
                Text("Categories")
                Spacer()
                if !categories.isEmpty {
                    if isEditing {
                        Button("Done") {
                            withAnimation { isEditing = false }
                        }
                        .foregroundStyle(.tint)
                    } else {
                        Button("Edit") {
                            withAnimation { isEditing = true }
                        }
                        .foregroundStyle(.tint)
                    }
                }
            }
            .foregroundStyle(.primary)
            .buttonStyle(.borderless)
            ForEach(categories) { category in
                categoryRow(for: category)
                    .onDrop(of: [UTType.text], delegate: CategoryDropDelegate(
                        target: category,
                        categories: categories,
                        dragging: $draggingCategory,
                        onMove: moveCategories
                    ))
            }
            Button {
                showNewCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
            .foregroundStyle(.tint)
            .buttonStyle(.borderless)
        }
        #else
        Section(header: Text("Categories").foregroundStyle(.black.opacity(0.5))) {
            ForEach(categories) { category in
                categoryRow(for: category)
            }
            Button {
                showNewCategory = true
            } label: {
                Label("New Category", systemImage: "plus")
            }
            .foregroundStyle(.tint)
        }
        #endif
    }

    // Separate @ViewBuilder function so #if inside ForEach doesn't confuse the type checker
    @ViewBuilder
    private func categoryRow(for category: CategoryItem) -> some View {
        let count = entryCount(for: category.name)
        #if os(macOS)
        CategoryRowView(
            category: category,
            count: count,
            isEditing: false,
            onTap: {},
            onEdit: { editingCategory = category },
            onDelete: { categoryToDelete = category }
        )
        .tag(SidebarSelection.category(category.name))
        #else
        CategoryRowView(
            category: category,
            count: count,
            isEditing: isEditing,
            onTap: { selection = .category(category.name); onSelect?() },
            onEdit: { editingCategory = category },
            onDelete: { categoryToDelete = category }
        )
        .onDrag {
            draggingCategory = category
            return NSItemProvider(object: category.name as NSString)
        }
        #endif
    }

    // MARK: - Static nav row helper

    @ViewBuilder
    private func navRow(_ label: String, icon: String, value: SidebarSelection) -> some View {
        #if os(macOS)
        Label(label, systemImage: icon)
            .tag(value)
        #else
        Button {
            selection = value
            onSelect?()   // Close the sidebar sheet on iPhone
        } label: {
            Label(label, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.primary)
        #endif
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        // Only show the close button on iPhone (sheet context); iPad uses split view
        if onSelect != nil {
            ToolbarItem(placement: .primaryAction) {
                Button { onSelect?() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.black)
                }
            }
        }
        #else
        ToolbarItem(placement: .primaryAction) {
            Button {
                showNewEntry = true
            } label: {
                Label("New Artifact", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        #endif

        #if os(macOS)
        ToolbarItem {
            Button("Backup", action: onBackupTapped)
        }
        #endif
    }

    // MARK: - Helpers

    private func entryCount(for name: String) -> Int {
        entries.filter { $0.categoryNames.contains(name) }.count
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reordered = Array(categories)
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
    }

    private func deleteCategory(_ cat: CategoryItem) {
        for entry in entries where entry.categoryNames.contains(cat.name) {
            entry.categoryNames.removeAll { $0 == cat.name }
        }
        modelContext.delete(cat)
        categoryToDelete = nil
        if selection == .category(cat.name) { selection = .all }
    }
}

// MARK: - Drop Delegate for category reordering

#if os(iOS)
private struct CategoryDropDelegate: DropDelegate {
    let target: CategoryItem
    let categories: [CategoryItem]
    @Binding var dragging: CategoryItem?
    let onMove: (IndexSet, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = dragging,
              dragging !== target,
              let from = categories.firstIndex(where: { $0 === dragging }),
              let to = categories.firstIndex(where: { $0 === target })
        else { return }
        withAnimation {
            onMove(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
#endif

// MARK: - Category Row (private struct keeps the type checker scope small)

private struct CategoryRowView: View {
    let category: CategoryItem
    let count: Int
    let isEditing: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        rowContent
            .contextMenu {
                Button("Edit", action: onEdit)
                Divider()
                Button("Delete", role: .destructive, action: onDelete)
            }
            #if os(iOS)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            .listRowSeparator(.hidden)
            #endif
    }

    @ViewBuilder
    private var rowContent: some View {
        #if os(macOS)
        HStack {
            Label(category.name, systemImage: category.icon)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        #else
        if isEditing {
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Label(category.name, systemImage: category.icon)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.borderless)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        } else {
            Button(action: onTap) {
                HStack {
                    Label(category.name, systemImage: category.icon)
                    Spacer()
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .foregroundStyle(.primary)
        }
        #endif
    }
}
private struct DeleteCategoryOverlay: View {
    let name: String
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Delete \"\(name)\"?")
                    .font(.headline)
                Text("Artifacts in this category won't be deleted.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                VStack(spacing: 8) {
                    Button("Delete Category", role: .destructive, action: onDelete)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .frame(maxWidth: .infinity)
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
}

