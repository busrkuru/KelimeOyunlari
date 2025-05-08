import SwiftUI
import FirebaseFirestore

struct ActiveGamesView: View {
    @State private var activeGames = [Game]()
    @State private var selectedGameId: String?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Aktif Oyunlar")
                    .font(.title)
                    .padding()

                List(activeGames) { game in
                    NavigationLink(destination: GameBoardView(gameId: game.id)) {
                        VStack(alignment: .leading) {
                            Text("\(game.player1) vs \(game.player2)")
                                .font(.headline)
                            Text("Puan: \(game.score1) - \(game.score2)")
                                .font(.subheadline)
                            Text("Zaman: \(game.gameTime) saniye")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .onAppear {
                fetchActiveGames()
            }
        }
    }

    func fetchActiveGames() {
        let db = Firestore.firestore()
        let gamesRef = db.collection("games").whereField("gameStatus", isEqualTo: "active")

        gamesRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Aktif oyunlar alınamadı: \(error.localizedDescription)")
            } else {
                activeGames = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    let game = Game(
                        id: document.documentID,
                        player1: data["player1Username"] as? String ?? "",
                        player2: data["player2Username"] as? String ?? "",
                        score1: (data["scores"] as? [String: Int])?[data["player1Id"] as? String ?? ""] ?? 0,
                        score2: (data["scores"] as? [String: Int])?[data["player2Id"] as? String ?? ""] ?? 0,
                        gameTime: data["gameTime"] as? Int ?? 0,
                        turn: data["turn"] as? String ?? "",
                        player1Id: data["player1Id"] as? String ?? "",
                        player2Id: data["player2Id"] as? String ?? "",
                        remainingLetters: data["remainingLetters"] as? [String: Int] ?? [:],
                        steppedOnMine: data["steppedOnMine"] as? [String: Bool] ?? [:],
                        mineEffects: data["mineEffects"] as? [String: [String]] ?? [:]
                    )
                    return game
                } ?? []
            }
        }
    }
}
