import Foundation

struct Game: Identifiable {
    var id: String
    var player1: String
    var player2: String
    var score1: Int
    var score2: Int
    var gameTime: Int
    var turn: String
    var player1Id: String
    var player2Id: String

    var remainingLetters: [String: Int]
    var steppedOnMine: [String: Bool]
    var mineEffects: [String: [String]]
}
