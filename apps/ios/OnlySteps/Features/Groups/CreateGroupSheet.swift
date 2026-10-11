import SwiftUI

struct CreateGroupSheet: View {
    let model: GroupsModel
    let onCreated: (StepGroup) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group name", text: $name)
                        .submitLabel(.done)
                        .onSubmit(save)
                } footer: {
                    Text("Weeks run Monday to Sunday in your time zone (\(TimeZone.current.identifier)).")
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(OSColor.destructive)
                }
            }
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: save)
                        .disabled(trimmedName.isEmpty || trimmedName.count > 60 || isSaving)
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty, !isSaving else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let group = try await model.create(name: trimmedName)
                dismiss()
                onCreated(group)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
