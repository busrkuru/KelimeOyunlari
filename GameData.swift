import Foundation

struct GameData {
    let id: String
    let player1Id: String
    let player2Id: String
    let letters: [String: [String]]
    let scores: [String: Int]
    let turn: String
    let gameTime: Int
    let gameStatus: String

    init(from dict: [String: Any], id: String) {
        self.id = id
        self.player1Id = dict["player1Id"] as? String ?? ""
        self.player2Id = dict["player2Id"] as? String ?? ""
        self.letters = dict["letters"] as? [String: [String]] ?? [:]
        self.scores = dict["scores"] as? [String: Int] ?? [:]
        self.turn = dict["turn"] as? String ?? ""
        self.gameTime = dict["gameTime"] as? Int ?? 0
        self.gameStatus = dict["gameStatus"] as? String ?? ""
    }
}
