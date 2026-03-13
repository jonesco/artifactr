import SwiftUI
import SwiftData

struct CategoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingCategories: [CategoryItem]

    var category: CategoryItem?
    var nextSortOrder: Int = 0

    @State private var name = ""
    @State private var selectedIcon = "folder"
    @State private var showDuplicateAlert = false

    private var isEditing: Bool { category != nil }
    private var isSaveDisabled: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                        #if os(iOS)
                        .font(.body)
                        #endif
                }

                Section("Icon") {
                    IconPickerView(
                        selectedIcon: $selectedIcon,
                        suggestions: CategoryItem.suggestedIcons(for: name)
                    )
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create", action: attemptSave)
                        .disabled(isSaveDisabled)
                }
            }
        }
        .onAppear {
            if let c = category {
                name = c.name
                selectedIcon = c.icon
            }
        }
        .alert("Name Already Exists", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A category named \"\(name.trimmingCharacters(in: .whitespaces))\" already exists. Choose a different name.")
        }
    }

    private func attemptSave() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let isDuplicate = existingCategories.contains {
            $0.name.lowercased() == trimmed.lowercased() && $0 !== category
        }
        guard !isDuplicate else {
            showDuplicateAlert = true
            return
        }
        if let existing = category {
            existing.name = trimmed
            existing.icon = selectedIcon
        } else {
            modelContext.insert(CategoryItem(name: trimmed, icon: selectedIcon, sortOrder: nextSortOrder))
        }
        dismiss()
    }
}
