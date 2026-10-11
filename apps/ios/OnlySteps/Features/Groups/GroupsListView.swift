import SwiftUI

struct GroupsListView: View {
    @Environment(AppModel.self) private var app
    @State private var model = GroupsModel()
    @State private var path: [StepGroup] = []
    @State private var isCreating = false
    @State private var joinRequest: JoinRequest?

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Groups")
                .navigationDestination(for: StepGroup.self) { GroupDetailView(group: $0) }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("New group", systemImage: "plus") { isCreating = true }
                            Button("Join with code", systemImage: "ticket") { joinRequest = JoinRequest(code: "") }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .refreshable { await model.load() }
                .task { await model.load() }
        }
        .sheet(isPresented: $isCreating) {
            CreateGroupSheet(model: model) { path.append($0) }
        }
        .sheet(item: $joinRequest) { request in
            JoinGroupSheet(model: model, initialCode: request.code) { group in
                path = [group]
            }
        }
        .onChange(of: app.pendingInviteCode, initial: true) { _, code in
            guard let code else { return }
            app.pendingInviteCode = nil
            joinRequest = JoinRequest(code: code)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.groups.isEmpty && !model.isLoading {
            ContentUnavailableView {
                Label("No groups yet", systemImage: "person.3")
            } description: {
                Text(model.errorMessage ?? "Create a group and invite friends, or join one with a code.")
            } actions: {
                Button("New group") { isCreating = true }.buttonStyle(.osPrimary)
                Button("Join with code") { joinRequest = JoinRequest(code: "") }.buttonStyle(.osSecondary)
            }
            .frame(maxWidth: 360)
        } else {
            ScrollView {
                LazyVStack(spacing: OSSpace._3) {
                    if let error = model.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(OSColor.destructive)
                    }
                    ForEach(model.groups) { group in
                        NavigationLink(value: group) {
                            OSCard {
                                HStack(spacing: OSSpace._3) {
                                    AvatarView(name: group.name)
                                    Text(group.name).font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(OSColor.mutedForeground)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(OSSpace._4)
            }
            .background(OSColor.background)
        }
    }
}

/// Identifiable wrapper so the join sheet can be driven by `sheet(item:)`.
private struct JoinRequest: Identifiable {
    let id = UUID()
    let code: String
}
