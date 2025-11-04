import Foundation
import Combine



class LevelService: ObservableObject {
    @Published var currentLevel: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let baseURL = "http://192.168.1.137:5001"
    
    func fetchCurrentLevel() {
        guard let url = URL(string: "\(baseURL)/getLevel") else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(LevelResponse.self, from: data)
                    self?.currentLevel = decoded.current_level
                    print("Current level fetched: \(decoded.current_level)")
                } catch {
                    self?.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func checkAnswer(levelId: Int, answer: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(baseURL)/checkLevel/\(levelId)") else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["answer": answer]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(false, "Failed to encode answer")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    completion(false, "No data received")
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(AnswerResponse.self, from: data)
                    
                    if decoded.success, let newLevel = decoded.new_level {
                        self?.currentLevel = newLevel
                    }
                    
                    completion(decoded.success, decoded.message)
                } catch {
                    // Try to decode as plain text if JSON fails
                    if let message = String(data: data, encoding: .utf8) {
                        completion(false, message)
                    } else {
                        completion(false, "Failed to decode response")
                    }
                }
            }
        }.resume()
    }
}
