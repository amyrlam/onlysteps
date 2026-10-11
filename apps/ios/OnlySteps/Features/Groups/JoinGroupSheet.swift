import SwiftUI

struct JoinGroupSheet: View {
    let model: GroupsModel
    let onJoined: (StepGroup) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    @State private var preview: InvitePreview?
    @State private var isJoining = false
    @State private var errorMessage: String?

    init(model: GroupsModel, initialCode: String = "", onJoined: @escaping (StepGroup) -> Void) {
        self.model = model
        self.onJoined = onJoined
        _input = State(initialValue: initialCode)
    }

    /// Accepts a bare code or a pasted invite link.
    private var code: String { InviteLink.normalize(input) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Invite code or link", text: $input)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                } footer: {
                    Text("Ask a group member to share their invite link.")
                }

                if let preview {
                    Section {
                        HStack(spacing: OSSpace._3) {
                            AvatarView(name: preview.name)
                            VStack(alignment: .leading) {
                                Text(preview.name).font(.headline)
                                Text("^[\(preview.memberCount) member](inflect: true)")
                                    .font(.subheadline)
                                    .foregroundStyle(OSColor.mutedForeground)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(OSColor.destructive)
                }
            }
            .navigationTitle("Join a group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Join", action: join).disabled(code.isEmpty || isJoining)
                }
            }
            .task(id: code) { await loadPreview() }
        }
    }

    private func loadPreview() async {
        preview = nil
        guard code.count >= 4 else { return }
        try? await Task.sleep(for: .milliseconds(300)) // wait for typing to pause
        guard !Task.isCancelled else { return }
        preview = try? await model.preview(code: code)
    }

    private func join() {
        guard !code.isEmpty, !isJoining else { return }
        isJoining = true
        Task {
            defer { isJoining = false }
            do {
                let group = try await model.join(code: code)
                dismiss()
                if let group { onJoined(group) }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
