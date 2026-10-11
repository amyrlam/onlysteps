import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class GroupsModel {
    private(set) var groups: [StepGroup] = []
    private(set) var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // RLS only returns groups the signed-in user belongs to.
            groups = try await supabase
                .from("groups")
                .select(StepGroup.columns)
                .order("created_at", ascending: false)
                .fetchValue()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates a group; a database trigger makes the creator its owner.
    func create(name: String) async throws -> StepGroup {
        let group: StepGroup = try await supabase
            .from("groups")
            .insert(NewGroup(name: name, timeZone: TimeZone.current.identifier))
            .select(StepGroup.columns)
            .single()
            .fetchValue()
        groups.insert(group, at: 0)
        return group
    }

    /// Joins by invite code and returns the joined group.
    func join(code: String) async throws -> StepGroup? {
        let groupID: UUID = try await supabase
            .rpc("join_group", params: ["code": code])
            .fetchValue()
        await load()
        return groups.first { $0.id == groupID }
    }

    /// Group name and size for an invite code, before joining.
    func preview(code: String) async throws -> InvitePreview? {
        let rows: [InvitePreview] = try await supabase
            .rpc("group_for_invite", params: ["code": code])
            .fetchValue()
        return rows.first
    }
}
