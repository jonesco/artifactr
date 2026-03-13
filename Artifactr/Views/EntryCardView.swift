import SwiftUI

struct EntryCardView: View {
    @Bindable var entry: Entry
    let categories: [CategoryItem]
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onOpen: () -> Void

    @State private var copied = false
    @State private var showImageFullScreen = false
    @State private var showDeleteConfirmation = false
    @State private var currentImageIndex = 0
    @State private var copyTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image carousel — tappable for full-screen
            if !entry.images.isEmpty {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(entry.images.enumerated()), id: \.offset) { idx, data in
                        thumbnailImage(data: data)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: entry.images.count > 1 ? .automatic : .never))
                .frame(height: 160)
                .contentShape(Rectangle())
                .onTapGesture { showImageFullScreen = true }
            }

            // Card body
            VStack(alignment: .leading, spacing: 12) {
                // Title row
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        entry.isFavorite.toggle()
                    } label: {
                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.tint)
                                .imageScale(.medium)
                        } else {
                            Image(systemName: "star")
                                .foregroundStyle(.secondary)
                                .imageScale(.medium)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Category badges
                if !entry.categoryNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(entry.categoryNames, id: \.self) { name in
                                categoryBadge(name)
                            }
                        }
                    }
                }

                // Tag badges
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(entry.tags, id: \.self) { tag in
                                tagBadge(tag)
                            }
                        }
                    }
                }

                Text(entry.createdAt.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Action bar
                HStack(spacing: 16) {
                    Button(action: copyToClipboard) {
                        if copied {
                            Label("Copied!", systemImage: "checkmark")
                                .font(.caption)
                                .foregroundStyle(Color.green)
                        } else {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .animation(.default, value: copied)

                    Spacer()

                    ShareLink(
                        item: entry,
                        preview: SharePreview(entry.title.isEmpty ? "Artifact" : entry.title)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Share artifact")

                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit artifact")

                    Button { showDeleteConfirmation = true } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete artifact")
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture { onOpen() }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
        )
        .contextMenu {
            Button(action: copyToClipboard) {
                Label("Copy Content", systemImage: "doc.on.doc")
            }
            ShareLink(
                item: entry,
                preview: SharePreview(entry.title.isEmpty ? "Artifact" : entry.title)
            ) {
                Label("Share Artifact", systemImage: "square.and.arrow.up")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button("Delete", role: .destructive) { showDeleteConfirmation = true }
        }
        .alert(
            "Delete this artifact?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete Artifact", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This artifact will be permanently deleted.")
        }
        .sheet(isPresented: $showImageFullScreen) {
            fullScreenImageSheet
        }
        .onDisappear {
            copyTask?.cancel()
        }
    }

    // MARK: - Image helpers

    @ViewBuilder
    private func thumbnailImage(data: Data) -> some View {
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

    @ViewBuilder
    private func fitImage(data: Data) -> some View {
        #if os(iOS)
        if let img = UIImage(data: data) {
            Image(uiImage: img).resizable().scaledToFit()
        } else {
            brokenImagePlaceholder
        }
        #else
        if let img = NSImage(data: data) {
            Image(nsImage: img).resizable().scaledToFit()
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

    @ViewBuilder
    private var fullScreenImageSheet: some View {
        NavigationStack {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(entry.images.enumerated()), id: \.offset) { idx, data in
                    fitImage(data: data)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: entry.images.count > 1 ? .automatic : .never))
            .background(Color.black)
            .ignoresSafeArea()
            .navigationTitle(entry.images.count > 1 ? "Image \(currentImageIndex + 1) of \(entry.images.count)" : "Image")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showImageFullScreen = false }
                }
            }
        }
    }

    // MARK: - Category badge

    @ViewBuilder
    private func categoryBadge(_ name: String) -> some View {
        let icon = categories.first(where: { $0.name == name })?.icon ?? "tag"
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(name)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundStyle(.tint)
        .background(.tint.opacity(0.15), in: Capsule())
    }

    // MARK: - Tag badge

    @ViewBuilder
    private func tagBadge(_ tag: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "number")
                .font(.caption2)
            Text(tag)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.primary.opacity(0.10))
        .foregroundStyle(Color.primary.opacity(0.6))
        .clipShape(Capsule())
    }

    // MARK: - Clipboard

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.content, forType: .string)
        #else
        UIPasteboard.general.string = entry.content
        #endif

        copyTask?.cancel()
        withAnimation { copied = true }
        copyTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { copied = false }
            }
        }
    }
}

