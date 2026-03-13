import SwiftUI
#if os(iOS)
import UIKit
#endif
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: Entry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showEditForm = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !entry.title.isEmpty {
                        Text(entry.title)
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !entry.images.isEmpty {
                        TabView {
                            ForEach(Array(entry.images.enumerated()), id: \.offset) { _, data in
                                #if os(iOS)
                                if let img = UIImage(data: data) {
                                    Image(uiImage: img).resizable().scaledToFit()
                                }
                                #else
                                if let img = NSImage(data: data) {
                                    Image(nsImage: img).resizable().scaledToFit()
                                }
                                #endif
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 280)
                        .background(Color(.secondarySystemBackground))
                    }

                    if !entry.content.isEmpty {
                        Text(entry.content)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !entry.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Wrap(tags: entry.tags)
                        }
                    }

                    Text(entry.createdAt.formatted(.dateTime))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .padding(.bottom, 120)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemBackground))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay(alignment: .bottom) {
            FloatingActionBar(
                entry: entry,
                onEdit: { showEditForm = true },
                onDelete: { showDeleteConfirm = true }
            )
            .padding(.bottom, 24)
        }
        .background(Color(.secondarySystemBackground))
        .ignoresSafeArea(edges: .bottom)
        #if os(iOS)
        .fullScreenCover(isPresented: $showEditForm) {
            EntryFormView(entry: entry)
        }
        #else
        .sheet(isPresented: $showEditForm) {
            EntryFormView(entry: entry)
                .frame(minWidth: 620, minHeight: 700)
        }
        #endif
        .confirmationDialog(
            "Delete this artifact?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Artifact", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct Wrap: View {
    let tags: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundStyle(Color.secondary)
                    .clipShape(Capsule())
            }
        }
    }
}

struct EntryReadOnlyView: View {
    let entry: Entry

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !entry.title.isEmpty {
                        Text(entry.title)
                            .font(.title2).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !entry.images.isEmpty {
                        TabView {
                            ForEach(Array(entry.images.enumerated()), id: \.offset) { _, data in
                                #if os(iOS)
                                if let img = UIImage(data: data) {
                                    Image(uiImage: img).resizable().scaledToFit()
                                }
                                #else
                                if let img = NSImage(data: data) {
                                    Image(nsImage: img).resizable().scaledToFit()
                                }
                                #endif
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 280)
                        .background(Color(.secondarySystemBackground))
                    }

                    if !entry.content.isEmpty {
                        Text(entry.content)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !entry.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Wrap(tags: entry.tags)
                        }
                    }

                    Text(entry.createdAt.formatted(.dateTime))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemBackground))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .ignoresSafeArea(edges: .bottom)
    }
}
private struct FloatingActionBar: View {
    let entry: Entry
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var copied = false

    var body: some View {
        HStack(spacing: 20) {
            // Copy
            Button {
                #if os(iOS)
                UIPasteboard.general.string = entry.content
                #endif
                withAnimation(.easeInOut(duration: 0.2)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.2)) { copied = false }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .imageScale(.large)
                    .foregroundStyle(copied ? .green : .secondary)
                    .accessibilityLabel("Copy")
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: copied)

            // Share
            ShareLink(item: entry, preview: SharePreview(entry.title.isEmpty ? "Artifact" : entry.title)) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
                    .accessibilityLabel("Share")
            }
            .buttonStyle(.plain)

            // Edit
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .imageScale(.large)
                    .accessibilityLabel("Edit")
            }
            .buttonStyle(.plain)

            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .imageScale(.large)
                    .accessibilityLabel("Delete")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .foregroundStyle(.secondary)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

