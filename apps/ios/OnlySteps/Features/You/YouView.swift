import SwiftUI

struct YouView: View {
    @Environment(AppModel.self) private var app
    @State private var today: Int?
    @State private var week: Int?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OSSpace._4) {
                    HStack(spacing: OSSpace._3) {
                        AvatarView(name: app.profile?.displayName ?? "", size: OSSpace._12)
                        VStack(alignment: .leading) {
                            Text(app.profile?.displayName ?? " ").font(.title3.bold())
                            Text(app.profile?.timeZone ?? TimeZone.current.identifier)
                                .font(.footnote)
                                .foregroundStyle(OSColor.mutedForeground)
                        }
                    }

                    HStack(spacing: OSSpace._3) {
                        stat("Today", today)
                        stat("This week", week)
                    }

                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(OSColor.destructive)
                    }

                    Text("Steps come from Apple Health. To change access, open Settings › Health › Data Access & Devices › \(AppConfig.displayName).")
                        .font(.footnote)
                        .foregroundStyle(OSColor.mutedForeground)

                    Button("Sign out", role: .destructive) {
                        Task { await app.signOut() }
                    }
                    .buttonStyle(.osDestructive)
                    .padding(.top, OSSpace._6)
                }
                .padding(OSSpace._4)
            }
            .background(OSColor.background)
            .navigationTitle("You")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func stat(_ title: String, _ steps: Int?) -> some View {
        OSCard {
            VStack(alignment: .leading, spacing: OSSpace._1) {
                Text(title).font(.subheadline).foregroundStyle(OSColor.mutedForeground)
                if let steps {
                    StepCountText(steps: steps, font: .title.bold())
                } else {
                    Text("–").font(.title.bold())
                }
            }
        }
    }

    private func load() async {
        do {
            let summary = try await StepSync.shared.localSummary()
            withAnimation {
                today = summary.today
                week = summary.week
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        await StepSync.shared.syncRecentDays()
    }
}
