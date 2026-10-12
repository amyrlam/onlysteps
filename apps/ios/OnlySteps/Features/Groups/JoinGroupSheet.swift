import SwiftUI

struct JoinGroupSheet: View {
    let model: GroupsModel
    let onJoined: (StepGroup) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input: String
    @State private var preview: InvitePreview?
    @State private var removal: GroupRemoval?
    @State private var isRequesting = false
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

                if let removal {
                    Section {
                        if removal.dismissedAt != nil {
                            Text("The owner removed you from this group and dismissed your request to rejoin.")
                                .foregroundStyle(OSColor.mutedForeground)
                        } else if removal.requestedAt != nil {
                            Label("Request sent. You’ll be back in the group once the owner approves it.", systemImage: "checkmark.circle")
                        } else {
                            Text("The owner removed you from this group. You can ask them to let you back in.")
                                .foregroundStyle(OSColor.mutedForeground)
                            Button("Request to rejoin", action: requestRejoin)
                                .disabled(isRequesting)
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
                    Button("Join", action: join).disabled(code.isEmpty || isJoining || removal != nil)
                }
            }
            .task(id: code) { await loadPreview() }
        }
    }

    private func loadPreview() async {
        preview = nil
        removal = nil
        errorMessage = nil
        guard code.count >= 4 else { return }
        try? await Task.sleep(for: .milliseconds(300)) // wait for typing to pause
        guard !Task.isCancelled else { return }
        preview = try? await model.preview(code: code)
        if let preview {
            removal = try? await model.removal(groupID: preview.id)
        }
    }

    private func requestRejoin() {
        guard let preview, !isRequesting else { return }
        isRequesting = true
        Task {
            defer { isRequesting = false }
            do {
                try await model.requestRejoin(code: code)
                errorMessage = nil
                removal = try? await model.removal(groupID: preview.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
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
                if let preview { removal = try? await model.removal(groupID: preview.id) }
            }
        }
    }
}
