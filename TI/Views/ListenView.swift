import SwiftUI
import AVFoundation

struct ListenView: View {
    @ObservedObject var levelService: LevelService
    @State private var player: AVAudioPlayer?
    @State private var playingLevel: Int? = nil
    @State private var timer: Timer?

    init(levelService: LevelService) {
        self.levelService = levelService
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erreur AVAudioSession: \(error)")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if levelService.isLoading {
                        ProgressView("Chargement du niveau...")
                            .padding(.top, 100)
                    } else if let error = levelService.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Erreur de connexion")
                                .font(.headline)
                            
                            Text(error)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .font(.subheadline)
                            
                            Button("Réessayer") {
                                levelService.fetchCurrentLevel()
                            }
                            .buttonStyle(MyButtonStyle(color: .blue))
                        }
                        .padding()
                        .padding(.top, 60)
                    } else if levelService.currentLevel >= 0 {
                        // Header with current level
                        VStack(spacing: 12) {
                            Text("Messages Vocaux de TI")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Écoutez les indices pour progresser")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        // Voice messages
                        VStack(spacing: 16) {
                            if levelService.currentLevel >= 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    LevelBadge(niveau: 0, color: .purple)
                                    VoiceMessageButton(
                                        niveau: 0,
                                        duration: "0:30",
                                        color: .purple,
                                        isPlaying: playingLevel == 0,
                                        action: { toggleSound(niveau: 0) }
                                    )
                                }
                            }
                            
                            if levelService.currentLevel >= 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    LevelBadge(niveau: 1, color: .blue)
                                    VoiceMessageButton(
                                        niveau: 1,
                                        duration: "0:45",
                                        color: .blue,
                                        isPlaying: playingLevel == 1,
                                        action: { toggleSound(niveau: 1) }
                                    )
                                }
                            }
                            
                            if levelService.currentLevel >= 2 {
                                VStack(alignment: .leading, spacing: 8) {
                                    LevelBadge(niveau: 2, color: .green)
                                    VoiceMessageButton(
                                        niveau: 2,
                                        duration: "1:02",
                                        color: .green,
                                        isPlaying: playingLevel == 2,
                                        action: { toggleSound(niveau: 2) }
                                    )
                                }
                            }
                            
                            if levelService.currentLevel >= 3 {
                                VStack(alignment: .leading, spacing: 8) {
                                    LevelBadge(niveau: 3, color: .orange)
                                    VoiceMessageButton(
                                        niveau: 3,
                                        duration: "0:58",
                                        color: .orange,
                                        isPlaying: playingLevel == 3,
                                        action: { toggleSound(niveau: 3) }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Refresh button
                        Button(action: {
                            levelService.fetchCurrentLevel()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Rafraîchir")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.purple)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                        }
                        .padding(.top, 20)
                        
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Aucun niveau disponible")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button("Charger le niveau") {
                                levelService.fetchCurrentLevel()
                            }
                            .buttonStyle(MyButtonStyle(color: .blue))
                        }
                        .padding(.top, 100)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Écouter")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                levelService.fetchCurrentLevel()
            }
            .onDisappear {
                stopAllSounds()
            }
        }
    }

    func toggleSound(niveau: Int) {
        // If this level is already playing, stop it
        if playingLevel == niveau {
            stopAllSounds()
            return
        }
        
        // Stop any currently playing sound
        stopAllSounds()
        
        // Play the new sound
        playSound(niveau: niveau)
    }
    
    func playSound(niveau: Int) {
        guard let url = Bundle.main.url(forResource: "level\(niveau)", withExtension: "wav") else {
            print("Fichier WAV level\(niveau).wav non trouvé")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            playingLevel = niveau
            print("Lecture level\(niveau).wav")
            
            // Monitor playback to update UI when finished
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = player, !player.isPlaying {
                    stopAllSounds()
                }
            }
        } catch {
            print("Erreur lecture audio : \(error)")
        }
    }
    
    func stopAllSounds() {
        player?.stop()
        player = nil
        playingLevel = nil
        timer?.invalidate()
        timer = nil
    }
}
