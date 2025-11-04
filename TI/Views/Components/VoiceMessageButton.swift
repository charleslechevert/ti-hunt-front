import SwiftUI

struct VoiceMessageButton: View {
    let niveau: Int
    let duration: String
    let color: Color
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Play button icon
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                
                // Waveform visualization
                HStack(spacing: 3) {
                    ForEach(0..<25, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(isPlaying ? 0.8 : 0.4))
                            .frame(width: 3, height: barHeight(for: index))
                            .animation(
                                isPlaying ?
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.05) :
                                    .default,
                                value: isPlaying
                            )
                    }
                }
                .frame(height: 40)
                
                Spacer()
                
                // Duration
                Text(duration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [8, 15, 22, 18, 25, 20, 12, 18, 28, 16, 20, 24, 14, 26, 18, 22, 12, 20, 16, 24, 18, 14, 22, 16, 20]
        let baseHeight = pattern[index % pattern.count]
        return isPlaying ? baseHeight * CGFloat.random(in: 0.7...1.3) : baseHeight
    }
}

// Level label badge
struct LevelBadge: View {
    let niveau: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 12))
            Text("Niveau \(niveau)")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

