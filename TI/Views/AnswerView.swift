import SwiftUI
import Combine

struct AnswerView: View {
    @ObservedObject var levelService: LevelService
    @State private var answer: String = ""
    @State private var isSubmitting: Bool = false
    @State private var feedbackMessage: String?
    @State private var isSuccess: Bool = false
    @State private var showCursor: Bool = true
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Terminal header
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    
                    Spacer()
                    
                    Text("Terminal — Niveau \(levelService.currentLevel)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                
                // Terminal content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Welcome message
                        Text("Last login: \(formattedDate()) on ttys000")
                            .terminalText()
                        
                        Divider()
                            .background(Color.green.opacity(0.3))
                            .padding(.vertical, 8)
                        
                        // Question prompt
                        HStack(alignment: .top, spacing: 0) {
                            Text("IOS-piraté")
                                .foregroundColor(.green)
                                .terminalText()
                            Text(" % ")
                                .foregroundColor(.white)
                                .terminalText()
                            Text("Quel est le secret trouvé?")
                                .terminalText()
                        }
                        
                        // Answer input line
                        HStack(alignment: .center, spacing: 0) {
                            Text("IOS-piraté")
                                .foregroundColor(.green)
                                .terminalText()
                            Text(" % ")
                                .foregroundColor(.white)
                                .terminalText()
                            
                            ZStack(alignment: .leading) {
                                if answer.isEmpty {
                                    Text(showCursor ? "▊" : "")
                                        .foregroundColor(.green)
                                        .terminalText()
                                }
                                
                                TextField("", text: $answer)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .onSubmit {
                                        submitAnswer()
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Feedback messages
                        if isSubmitting {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                    .scaleEffect(0.7)
                                Text("Vérification en cours...")
                                    .terminalText()
                                    .foregroundColor(.yellow)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if let feedback = feedbackMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                if isSuccess {
                                    Text("✓ SUCCESS")
                                        .terminalText()
                                        .foregroundColor(.green)
                                        .fontWeight(.bold)
                                    
                                    Text(feedback)
                                        .terminalText()
                                        .foregroundColor(.green)
                                    
                                    Text("Niveau débloqué: \(levelService.currentLevel)")
                                        .terminalText()
                                        .foregroundColor(.cyan)
                                } else {
                                    Text("✗ ERROR")
                                        .terminalText()
                                        .foregroundColor(.red)
                                        .fontWeight(.bold)
                                    
                                    Text(feedback)
                                        .terminalText()
                                        .foregroundColor(.red)
                                    
                                    Text("Réessayez...")
                                        .terminalText()
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Help text
                        if answer.isEmpty && feedbackMessage == nil {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Aide:")
                                    .terminalText()
                                    .foregroundColor(.gray)
                                    .padding(.top, 16)
                                
                                Text("• Tapez votre réponse et appuyez sur Entrée")
                                    .terminalText()
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                                
                                Text("• La réponse est sensible à la casse")
                                    .terminalText()
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
                .background(Color.black)
                
                // Bottom action bar
                HStack {
                    Button(action: {
                        answer = ""
                        feedbackMessage = nil
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Effacer")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Button(action: submitAnswer) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                            Text("Envoyer")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(6)
                    }
                    .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .opacity(answer.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            }
            .navigationBarHidden(true)
        }
        .onReceive(timer) { _ in
            showCursor.toggle()
        }
    }
    
    private func submitAnswer() {
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespaces)
        guard !trimmedAnswer.isEmpty else { return }
        
        isSubmitting = true
        feedbackMessage = nil
        
        levelService.checkAnswer(levelId: levelService.currentLevel, answer: trimmedAnswer) { success, message in
            isSubmitting = false
            isSuccess = success
            feedbackMessage = message
            
            if success {
                // Clear the answer field on success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    answer = ""
                }
                
                // Refresh the current level after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    levelService.fetchCurrentLevel()
                    feedbackMessage = nil
                }
            }
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d HH:mm:ss"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: Date())
    }
}

// Terminal text style modifier
extension Text {
    func terminalText() -> some View {
        self
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.white)
    }
}

// Preview
struct AnswerView_Previews: PreviewProvider {
    static var previews: some View {
        AnswerView(levelService: LevelService())
    }
}
