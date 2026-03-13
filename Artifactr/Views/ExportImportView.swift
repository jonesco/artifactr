import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]
    @Query private var categories: [CategoryItem]

    /// Pass `false` when presenting as a NavigationStack destination (avoids nested nav).
    /// Defaults to `true` for sheet usage.
    var showsNavigationChrome: Bool = true
    /// Called instead of `dismiss()` when the view is shown as a tab overlay rather than a sheet.
    var onComplete: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("accent") private var accentRaw: String = AccentChoice.blue.rawValue

    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDocument: JSONDocument?
    @State private var importResult: ImportResult?
    @State private var isImporting = false

    enum ImportResult: Identifiable {
        case success(entries: Int, categories: Int)
        case failure(String)
        var id: String {
            switch self {
            case .success(let e, let c): return "ok-\(e)-\(c)"
            case .failure(let m): return "fail-\(m)"
            }
        }
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
    }
    #endif

    // MARK: - Shared form (platform-agnostic)

    private var sharedForm: some View {
        Form {
            // Appearance
            Section("Appearance") {
                Picker("Theme", selection: $appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Accent Color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    AccentPalette(selection: $accentRaw)
                }
                .accessibilityElement(children: .contain)
            }

            // Export
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Save your artifacts and categories to a JSON file. Use it as a backup or to transfer data to another device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Export")
            } footer: {
                Text("\(entries.count) artifact\(entries.count == 1 ? "" : "s"), \(categories.count) categor\(categories.count == 1 ? "y" : "ies")")
            }

            // Import
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Import an Artifactr JSON backup. Your existing data is preserved — duplicate artifacts (matched by ID) are skipped.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showImporter = true
                    } label: {
                        if isImporting {
                            Label("Importing…", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Import Backup", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImporting)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Import")
            }

            // Result banner
            if let result = importResult {
                Section {
                    switch result {
                    case .success(let e, let c):
                        Label(
                            "Added \(e) artifact\(e == 1 ? "" : "s") and \(c) categor\(c == 1 ? "y" : "ies").",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("More")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .contentMargins(.bottom, onComplete != nil ? 88 : 0, for: .scrollContent)
        .toolbar {
            // Only show Done when presented as a modal sheet, not as a page.
            if onComplete == nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "artifactr-backup-\(todayString())"
        ) { _ in
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result: result)
        }
    }

    // MARK: - Export

    private func prepareExport() {
        let iso = ISO8601DateFormatter()

        let entryBackups = entries.map { e in
            EntryBackup(
                id: e.uuid.uuidString,
                title: e.title,
                content: e.content,
                isFavorite: e.isFavorite,
                categoryNames: e.categoryNames,
                tags: e.tags,
                createdAt: iso.string(from: e.createdAt)
            )
        }

        let categoryBackups = categories.map { c in
            CategoryBackup(name: c.name, icon: c.icon)
        }

        let backup = ArtifactrBackup(
            version: 2,
            exportedAt: iso.string(from: Date()),
            entries: entryBackups,
            categories: categoryBackups
        )

        do {
            let data = try JSONEncoder().encode(backup)
            exportDocument = JSONDocument(data: data)
            showExporter = true
        } catch {
            importResult = .failure("Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Import

    private func handleImport(result: Result<URL, Error>) {
        isImporting = true
        importResult = nil

        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importResult = .failure("Permission denied")
                isImporting = false
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let backup = try JSONDecoder().decode(ArtifactrBackup.self, from: data)

                let existingCatNames = Set(categories.map { $0.name })
                let existingIDs      = Set(entries.map { $0.uuid.uuidString })
                let iso = ISO8601DateFormatter()

                var catsAdded    = 0
                var entriesAdded = 0

                for cb in backup.categories where !existingCatNames.contains(cb.name) {
                    modelContext.insert(CategoryItem(name: cb.name, icon: cb.icon))
                    catsAdded += 1
                }

                for eb in backup.entries where !existingIDs.contains(eb.id) {
                    let item = Entry(
                        title: eb.title,
                        content: eb.content,
                        isFavorite: eb.isFavorite,
                        categoryNames: eb.categoryNames,
                        tags: eb.tags
                    )
                    if let parsedUUID = UUID(uuidString: eb.id) { item.uuid = parsedUUID }
                    if let date = iso.date(from: eb.createdAt) { item.createdAt = date }
                    modelContext.insert(item)
                    entriesAdded += 1
                }

                importResult = .success(entries: entriesAdded, categories: catsAdded)
            } catch {
                importResult = .failure(error.localizedDescription)
            }

        case .failure(let error):
            importResult = .failure(error.localizedDescription)
        }

        isImporting = false
    }

    private func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - AccentPalette and AccentSwatch helper views

private struct AccentPalette: View {
    @Binding var selection: String

    private let choices = AccentChoice.allCases

    var body: some View {
        HStack(spacing: 12) {
            ForEach(choices) { choice in
                AccentSwatch(choice: choice, isSelected: selection == choice.rawValue) {
                    selection = choice.rawValue
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AccentSwatch: View {
    let choice: AccentChoice
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(choice.color)
                    .frame(width: 28, height: 28)
                if isSelected {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.9), lineWidth: 2)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .shadow(radius: 1)
                                .offset(x: 10, y: -10)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label(for: choice)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func label(for choice: AccentChoice) -> String {
        switch choice {
        case .blue: return "Blue"
        case .indigo: return "Indigo"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .purple: return "Purple"
        }
    }
}

// MARK: - FileDocument wrapper

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
