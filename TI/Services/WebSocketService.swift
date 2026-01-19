import Foundation
import Combine

class GameWebSocketService: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?

    @Published var receivedLevel: Int? = nil

    func connect() {
        guard let url = URL(string: "ws://192.168.1.50:5001/ws") else { return }

        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket error:", error)

            case .success(let message):
                if case let .string(text) = message {
                    self?.handleMessage(text)
                }
            }

            self?.listen() // continue à écouter
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(LevelResponse.self, from: data)
        else { return }

        DispatchQueue.main.async {
            self.receivedLevel = decoded.current_level
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
