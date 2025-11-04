struct AnswerResponse: Codable {
    let success: Bool
    let message: String
    let new_level: Int?
}
