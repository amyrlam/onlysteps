import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var app = app

        SwiftUI.Group {
            switch app.authState {
            case .loading:
                ProgressView()
            case .signedOut:
                SignInView()
            case .signedIn:
                TabView(selection: $app.selectedTab) {
                    Tab("Groups", systemImage: "person.3.fill", value: AppTab.groups) {
                        GroupsListView()
                    }
                    Tab("You", systemImage: "figure.walk", value: AppTab.you) {
                        YouView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OSColor.background)
        .task { await app.observeAuth() }
        .onOpenURL { app.handle(url: $0) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { app.syncStepsIfSignedIn() }
        }
    }
}
