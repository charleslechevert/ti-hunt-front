import SwiftUI
import AVFoundation
import Combine



// MARK: - Content View
struct ContentView: View {
    @StateObject private var levelService = LevelService()
    @State private var player: AVAudioPlayer?

    init() {
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur AVAudioSession: \(error)")
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Escape Game Talkie")
                .font(.largeTitle)
                .padding()
            
            if levelService.isLoading {
                ProgressView("Chargement du niveau...")
            } else if let error = levelService.errorMessage {
                VStack {
                    Text("Erreur: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    Button("Réessayer") {
                        levelService.fetchCurrentLevel()
                    }
                    .buttonStyle(MyButtonStyle(color: .gray))
                }
            } else if levelService.currentLevel > 0 {
                Text("Niveau actuel: \(levelService.currentLevel)")
                    .font(.headline)
                
                // Display buttons only for levels <= current level
                if levelService.currentLevel >= 1 {
                    Button("Jouer son Niveau 1") { playSound(niveau: 1) }
                        .buttonStyle(MyButtonStyle(color: .blue))
                }
                
                if levelService.currentLevel >= 2 {
                    Button("Jouer son Niveau 2") { playSound(niveau: 2) }
                        .buttonStyle(MyButtonStyle(color: .green))
                }
                
                if levelService.currentLevel >= 3 {
                    Button("Jouer son Niveau 3") { playSound(niveau: 3) }
                        .buttonStyle(MyButtonStyle(color: .orange))
                }
                
                Button("Rafraîchir le niveau") {
                    levelService.fetchCurrentLevel()
                }
                .buttonStyle(MyButtonStyle(color: .purple))
            } else {
                Text("Aucun niveau disponible")
                    .foregroundColor(.gray)
                
                Button("Charger le niveau") {
                    levelService.fetchCurrentLevel()
                }
                .buttonStyle(MyButtonStyle(color: .blue))
            }
        }
        .padding()
        .onAppear {
            // Automatically fetch level when view appears
            levelService.fetchCurrentLevel()
        }
    }

    func playSound(niveau: Int) {
        guard let url = Bundle.main.url(forResource: "niveau\(niveau)", withExtension: "mp3") else {
            print("Fichier MP3 niveau\(niveau).mp3 non trouvé")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            print("Lecture niveau\(niveau).mp3")
        } catch {
            print("Erreur lecture audio : \(error)")
        }
    }
}

// MARK: - Button Style
struct MyButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
