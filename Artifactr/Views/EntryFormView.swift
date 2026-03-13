import SwiftUI
import SwiftData
#if os(iOS)
import PhotosUI
#endif

struct EntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.name) private var categories: [CategoryItem]

    var entry: Entry?
    /// Pre-select a category by name (e.g. when creating from inside a category view).
    var preselectedCategory: String? = nil
    /// Pass `false` when presenting as a NavigationStack destination (avoids nested nav).
    /// Defaults to `true` for sheet usage.
    var showsNavigationChrome: Bool = true
    /// Called instead of `dismiss()` when the form is shown as a tab overlay rather than a sheet.
    var onComplete: (() -> Void)? = nil

    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategories: Set<String> = []
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var showNewCategory = false
    @State private var imageList: [Data] = []

    #if os(iOS)
    @State private var pendingPhotos: [PhotosPickerItem] = []
    @State private var photoLoadTask: Task<Void, Never>?
    #else
    @State private var showImagePicker = false
    #endif

    private var isEditing: Bool { entry != nil }
    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty ||
        (!isEditing && selectedCategories.isEmpty)
    }

    /// True when shown as a persistent page (bottom nav tab), not a modal sheet.
    private var isPageMode: Bool { onComplete != nil }

    private func done() {
        if let onComplete { onComplete() } else { dismiss() }
    }

    private func clearForm() {
        title = ""
        content = ""
        selectedCategories = []
        tags = []
        tagInput = ""
        imageList = []
    }

    var body: some View {
        #if os(iOS)
        iosBody
        #else
        macBody
        #endif
    }

    // MARK: - Platform bodies

    #if os(iOS)
    @ViewBuilder
    private var iosBody: some View {
        if showsNavigationChrome {
            NavigationStack { sharedForm }
                .navigationBarTitleDisplayMode(.inline)
        } else {
            sharedForm
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    #else
    private var macBody: some View {
        NavigationStack { sharedForm }
            .fileImporter(
                isPresented: $showImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    for url in urls {
                        guard url.startAccessingSecurityScopedResource() else { continue }
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url) {
                            imageList.append(data)
                        }
                    }
                }
            }
    }
    #endif

    // MARK: - Shared form (platform-agnostic)

    private var sharedForm: some View {
        Form {
            titleSection
            contentSection
            categorySection
            tagsSection
            imageSection
        }
        .navigationTitle(isEditing ? "Edit Artifact" : "New Artifact")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if isPageMode {
                // Page — Cancel closes the workflow.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { done() }
                }
            } else {
                // Modal sheet — standard Cancel/Save pattern.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { done() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Create", action: save)
                    .disabled(isSaveDisabled)
            }
        }
        .contentMargins(.bottom, 0, for: .scrollContent)
        .onAppear(perform: populateIfEditing)
        .sheet(isPresented: $showNewCategory, onDismiss: autoSelectNewestCategory) {
            CategoryFormView(category: nil)
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section("Title") {
            TextField("Give this artifact a name", text: $title)
        }
    }

    private var contentSection: some View {
        Section {
            TextEditor(text: $content)
                .frame(minHeight: 160)
        } header: {
            HStack {
                Text("Content")
                Spacer()
                #if os(iOS)
                Button("Select All") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.selectAll(_:)),
                        to: nil, from: nil, for: nil
                    )
                }
                .font(.caption)
                .textCase(nil)
                #endif
            }
        }
    }

    private var categorySection: some View {
        Section {
            ForEach(categories) { cat in
                Button {
                    if selectedCategories.contains(cat.name) {
                        selectedCategories.remove(cat.name)
                    } else {
                        selectedCategories.insert(cat.name)
                    }
                } label: {
                    HStack {
                        Label(cat.name, systemImage: cat.icon)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedCategories.contains(cat.name) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Button {
                showNewCategory = true
            } label: {
                Label("New Category…", systemImage: "plus.circle")
            }
            .foregroundStyle(.tint)
        } header: {
            Text("Categories")
        }
    }

    private var tagsSection: some View {
        Section {
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(Color.secondary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            HStack {
                TextField("Add a tag", text: $tagInput)
                    .onSubmit { addTag() }
                Button("Add", action: addTag)
                    .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(.tint)
            }
        } header: {
            Text("Tags")
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        Section("Images") {
            imageSectionContent
        }
    }

    @ViewBuilder
    private var imageSectionContent: some View {
        if !imageList.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(imageList.indices, id: \.self) { idx in
                        ZStack(alignment: .topTrailing) {
                            thumbnailView(data: imageList[idx])
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Button {
                                imageList.remove(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }

        #if os(iOS)
        PhotosPicker(selection: $pendingPhotos, maxSelectionCount: 20, matching: .images) {
            Label("Add Images", systemImage: "photo.badge.plus")
        }
        .foregroundStyle(.tint)
        .padding(.bottom, 24)
        .onChange(of: pendingPhotos) { _, new in
            guard !new.isEmpty else { return }
            photoLoadTask?.cancel()
            photoLoadTask = Task {
                for item in new {
                    guard !Task.isCancelled else { break }
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        imageList.append(data)
                    }
                }
                pendingPhotos = []
            }
        }
        #else
        Button {
            showImagePicker = true
        } label: {
            Label("Add Images", systemImage: "photo.badge.plus")
        }
        .foregroundStyle(.tint)
        #endif
    }

    // MARK: - Platform thumbnail

    @ViewBuilder
    private func thumbnailView(data: Data) -> some View {
        #if os(iOS)
        if let img = UIImage(data: data) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            brokenImagePlaceholder
        }
        #else
        if let img = NSImage(data: data) {
            Image(nsImage: img).resizable().scaledToFill()
        } else {
            brokenImagePlaceholder
        }
        #endif
    }

    private var brokenImagePlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.15)
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Logic

    private func populateIfEditing() {
        if let e = entry {
            title = e.title
            content = e.content
            selectedCategories = Set(e.categoryNames)
            tags = e.tags
            imageList = e.images
        } else if let cat = preselectedCategory,
                  categories.contains(where: { $0.name == cat }) {
            // Context-aware: user is inside a specific category
            selectedCategories = [cat]
        } else if let last = UserDefaults.standard.string(forKey: "lastUsedCategory"),
                  categories.contains(where: { $0.name == last }) {
            // Fall back to last used category
            selectedCategories = [last]
        } else if let first = categories.first {
            // Default to first category in the list
            selectedCategories = [first.name]
        }
    }

    private func autoSelectNewestCategory() {
        if let newest = categories.max(by: { $0.createdAt < $1.createdAt }) {
            selectedCategories.insert(newest.name)
        }
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !tags.contains(trimmed) else {
            tagInput = ""
            return
        }
        tags.append(trimmed)
        tagInput = ""
    }

    private func save() {
        let trimTitle   = title.trimmingCharacters(in: .whitespaces)
        let trimContent = content.trimmingCharacters(in: .whitespaces)
        let catNames    = Array(selectedCategories).sorted()

        if let existing = entry {
            existing.title         = trimTitle
            existing.content       = trimContent
            existing.categoryNames = catNames
            existing.tags          = tags
            existing.images        = imageList
        } else {
            modelContext.insert(Entry(
                title: trimTitle,
                content: trimContent,
                categoryNames: catNames,
                tags: tags,
                images: imageList
            ))
        }

        // Remember the last used category for next time
        if let last = catNames.first {
            UserDefaults.standard.set(last, forKey: "lastUsedCategory")
        }

        done()
    }
}
