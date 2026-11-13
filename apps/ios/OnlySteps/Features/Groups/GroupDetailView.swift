import SwiftUI

struct GroupDetailView: View {
    let group: StepGroup

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: LeaderboardModel
    /// False while the podium waits at zero, then true as it grows.
    @State private var revealed = false
    @State private var confettiRun = 0

    init(group: StepGroup) {
        self.group = group
        _model = State(initialValue: LeaderboardModel(groupID: group.id, timeZone: group.timeZone))
    }

    private var inviteURL: URL { AppConfig.inviteURL(code: group.inviteCode) }

    private var weekTitle: String {
        switch model.weekOffset {
        case 0: return "This week"
        case -1: return "Last week"
        default:
            let calendar = StepCalendar(timeZone: model.timeZone).calendar
            let start = model.weekStart
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            var style = Date.FormatStyle().month(.abbreviated).day()
            style.timeZone = model.timeZone
            return "\(start.formatted(style)) – \(end.formatted(style))"
        }
    }

    /// Grows the podium from zero and throws confetti. With Reduce Motion
    /// on, the standings just appear.
    private func playReveal() {
        guard !reduceMotion, model.entries.contains(where: { $0.totalSteps > 0 }) else {
            revealed = true
            return
        }
        revealed = false
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.spring(duration: 1.6, bounce: 0.2)) { revealed = true }
            confettiRun += 1
        }
    }

    private func weekButton(_ label: String, systemImage: String, by change: Int) -> some View {
        Button {
            Task {
                await model.showWeek(offset: model.weekOffset + change)
                playReveal()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OSSpace._6) {
                HStack(spacing: OSSpace._3) {
                    AvatarView(name: group.name, imageURL: AppConfig.groupPictureURL(group.id), size: OSSpace._12)
                    VStack(alignment: .leading, spacing: OSSpace._1) {
                        Text(weekTitle).font(.title2.bold())
                        Text("Monday to Sunday")
                            .font(.footnote)
                            .foregroundStyle(OSColor.mutedForeground)
                    }
                    Spacer(minLength: 0)
                    weekButton("Earlier week", systemImage: "chevron.left", by: -1)
                    weekButton("Later week", systemImage: "chevron.right", by: 1)
                        .disabled(model.weekOffset == 0)
                }

                if let error = model.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(OSColor.destructive)
                }

                if model.entries.isEmpty {
                    if model.hasLoaded {
                        Text("No members yet.").foregroundStyle(OSColor.mutedForeground)
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                } else {
                    PodiumView(entries: Array(model.entries.prefix(3)), myID: app.userID, revealed: revealed)
                    VStack(spacing: OSSpace._2) {
                        ForEach(model.entries.dropFirst(3)) { entry in
                            LeaderboardRow(entry: entry, isMe: entry.userID == app.userID, revealed: revealed)
                        }
                    }
                    if !reduceMotion {
                        Button("Replay", systemImage: "arrow.counterclockwise", action: playReveal)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }

                if !model.records.isEmpty {
                    OSCard {
                        VStack(alignment: .leading, spacing: OSSpace._3) {
                            Text("Records").font(.headline)
                            ForEach(model.records) { record in
                                HStack(spacing: OSSpace._3) {
                                    AvatarView(name: record.entry.displayName, imageURL: record.entry.avatarURL, size: OSSpace._10)
                                    VStack(alignment: .leading) {
                                        Text(record.title)
                                            .font(.footnote)
                                            .foregroundStyle(OSColor.mutedForeground)
                                        Text(record.entry.userID == app.userID ? "You" : record.entry.displayName)
                                            .font(.body.weight(.semibold))
                                    }
                                    Spacer()
                                    StepCountText(steps: record.steps, font: .body.weight(.semibold))
                                }
                            }
                        }
                    }
                }

                OSCard {
                    VStack(alignment: .leading, spacing: OSSpace._3) {
                        Text("Invite friends").font(.headline)
                        Text("Code: \(group.inviteCode)")
                            .font(.body.monospaced())
                            .foregroundStyle(OSColor.mutedForeground)
                            .textSelection(.enabled)
                        ShareLink(item: inviteURL, subject: Text("Join \(group.name)"), message: Text("Join my \(AppConfig.displayName) group “\(group.name)”")) {
                            Label("Share invite link", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.osPrimary)
                    }
                }
            }
            .padding(OSSpace._4)
        }
        .background(OSColor.background)
        .overlay { ConfettiView(run: confettiRun) }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: inviteURL) {
                    Label("Invite", systemImage: "person.badge.plus")
                }
            }
        }
        .refreshable { await model.refresh() }
        .task {
            await model.load()
            playReveal()
            await model.loadRecords()
        }
    }
}

/// Top three on pedestals: 2nd, 1st, 3rd from left to right.
private struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let myID: UUID?
    let revealed: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: OSSpace._3) {
            ForEach([1, 0, 2], id: \.self) { index in
                if index < entries.count {
                    spot(entries[index], height: [OSSpace._16 + OSSpace._8, OSSpace._16, OSSpace._12][index])
                } else {
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func spot(_ entry: LeaderboardEntry, height: CGFloat) -> some View {
        let isMe = entry.userID == myID
        return VStack(spacing: OSSpace._2) {
            AvatarView(name: entry.displayName, imageURL: entry.avatarURL, size: OSSpace._12, isHighlighted: isMe)
            Text(isMe ? "You" : entry.displayName)
                .font(.subheadline.weight(isMe ? .bold : .medium))
                .lineLimit(1)
            StepCountText(steps: revealed ? entry.totalSteps : 0, font: .footnote)
                .foregroundStyle(OSColor.mutedForeground)
            RoundedRectangle(cornerRadius: OSRadius.md, style: .continuous)
                .fill(RankBadge.color(for: entry.rank).opacity(0.25))
                // Never shorter than the rank badge sitting on it.
                .frame(height: revealed ? height : OSSpace._12)
                .overlay(alignment: .top) {
                    RankBadge(rank: entry.rank).padding(.top, OSSpace._2)
                }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool
    let revealed: Bool

    var body: some View {
        HStack(spacing: OSSpace._3) {
            Text(entry.rank, format: .number)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(OSColor.mutedForeground)
                .frame(minWidth: OSSpace._6)
            AvatarView(name: entry.displayName, imageURL: entry.avatarURL, size: OSSpace._8)
            Text(isMe ? "\(entry.displayName) (you)" : entry.displayName)
                .font(.body.weight(isMe ? .semibold : .regular))
                .lineLimit(1)
            Spacer()
            StepCountText(steps: revealed ? entry.totalSteps : 0, font: .body.weight(.semibold))
        }
        .padding(.horizontal, OSSpace._4)
        .padding(.vertical, OSSpace._3)
        .foregroundStyle(isMe ? OSColor.accentForeground : OSColor.cardForeground)
        .background(isMe ? OSColor.accent : OSColor.card, in: RoundedRectangle(cornerRadius: OSRadius.md, style: .continuous))
    }
}
