import SwiftUI

struct MainTabView: View {
    @StateObject private var levelService = LevelService()
    
    var body: some View {
        TabView {
            ListenView(levelService: levelService)
                .tabItem {
                    Label("Écouter", systemImage: "headphones")
                }
            
            AnswerView(levelService: levelService)
                .tabItem {
                    Label("Répondre", systemImage: "paperplane")
                }
        }
    }
}
