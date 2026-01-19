import SwiftUI

struct MainTabView: View {
    @StateObject private var levelService = LevelService()
    @StateObject private var socketService = GameWebSocketService()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ListenView(levelService: levelService)
                .tabItem {
                    Label("Écouter", systemImage: "headphones")
                }
                .tag(0)

            AnswerView(levelService: levelService, selectedTab: $selectedTab)
                .tabItem {
                    Label("Répondre", systemImage: "paperplane")
                }
                .tag(1)

            /*CameraView()
                .tabItem {
                    Label("Caméra", systemImage: "camera")
                }
                .tag(2)*/
        }
        .onAppear {
            socketService.connect()
        }
        .onDisappear {
            socketService.disconnect()
        }
        .onReceive(socketService.$receivedLevel) { newLevel in
            if let level = newLevel {
                levelService.updateLevelFromWebSocket(level)
            }
        }
    }
}


