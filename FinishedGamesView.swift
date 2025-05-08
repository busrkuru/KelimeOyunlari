import SwiftUI
import FirebaseFirestore

struct FinishedGamesView: View {
    @State private var finishedGames = [Game]()

    var body: some View {
        VStack {
            Text("Biten Oyunlar")
                .font(.title)
                .padding()

            List(finishedGames) { game in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(game.player1) vs \(game.player2)")
                        .font(.headline)

                    Text("🔢 Puan: \(game.score1) - \(game.score2)")

                    Text("🏆 Sonuç: ") +
                    Text(game.score1 == game.score2 ? "Berabere" :
                         (game.score1 > game.score2 ? "Kazanan: \(game.player1)" : "Kazanan: \(game.player2)"))
                        .foregroundColor(game.score1 == game.score2 ? .gray :
                                         (game.score1 > game.score2 ? .green : .red))

                    Divider()

                    Group {
                        Text("🎯 \(game.player1):")
                        Text("   • Kalan harf: \(game.remainingLetters[game.player1Id] ?? 0)")
                        Text("   • Mayına bastı: \(game.steppedOnMine[game.player1Id] == true ? "Evet" : "Hayır")")
                        if let effects = game.mineEffects[game.player1Id], !effects.isEmpty {
                            Text("   • Etkiler: \(effects.joined(separator: ", "))")
                        }

                        Text("🎯 \(game.player2):")
                        Text("   • Kalan harf: \(game.remainingLetters[game.player2Id] ?? 0)")
                        Text("   • Mayına bastı: \(game.steppedOnMine[game.player2Id] == true ? "Evet" : "Hayır")")
                        if let effects = game.mineEffects[game.player2Id], !effects.isEmpty {
                            Text("   • Etkiler: \(effects.joined(separator: ", "))")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            fetchFinishedGames()
        }
    }

    func fetchFinishedGames() {
        let db = Firestore.firestore()
        let gamesRef = db.collection("games").whereField("gameStatus", isEqualTo: "finished")

        gamesRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Biten oyunlar alınamadı: \(error.localizedDescription)")
            } else {
                finishedGames = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    return Game(
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
                } ?? []
            }
        }
    }
}
