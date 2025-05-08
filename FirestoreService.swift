import Foundation
import FirebaseFirestore

class FirestoreService: ObservableObject {
    @Published var boardLetters: [[String]] = Array(repeating: Array(repeating: "", count: 15), count: 15)
    
    enum MineType: Int {
        case pointReduction = 1     // Puan Bölünmesi (%30)
        case pointTransfer = 2      // Puan rakibe geçer
        case letterLoss = 3         // Harfler havuza, yeni 7 harf
        case bonusCancel = 4        // Çarpanlar devre dışı
        case wordCancel = 5         // Puan iptali
    }

    enum RewardType: Int {
        case zoneBan = 1            // Bölge Yasağı
        case letterFreeze = 2      // Harf Yasağı
        case extraMove = 3         // Ekstra Hamle
    }

    // Aktif oyunu getir ve board'u doldur
    func fetchActiveGame(for userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("games")
            .whereField("gameStatus", isEqualTo: "active")
            .whereFilter(Filter.orFilter([
                Filter.whereField("player1Id", isEqualTo: userId),
                Filter.whereField("player2Id", isEqualTo: userId)
            ]))
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents,
                   let doc = documents.first,
                   let flatBoard = doc.data()["board"] as? [String] {

                    let board: [[String]] = stride(from: 0, to: 225, by: 15).map {
                        Array(flatBoard[$0..<min($0 + 15, flatBoard.count)])
                    }
                    DispatchQueue.main.async {
                        self.boardLetters = board
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            }
    }

    // Aktif eşleşmiş bir oyun varsa gameId'sini getir
    func checkIfUserHasMatchedGame(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("games")
            .whereField("gameStatus", isEqualTo: "active")
            .whereFilter(Filter.orFilter([
                Filter.whereField("player1Id", isEqualTo: uid),
                Filter.whereField("player2Id", isEqualTo: uid)
            ]))
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else if let doc = snapshot?.documents.first {
                    completion(.success(doc.documentID))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Eşleşmiş oyun bulunamadı"])))
                }
            }
    }

    // Mayın tablosu oluştur
    func generateMineBoard(rows: Int = 15, cols: Int = 15) -> [Int] {
        var board = Array(repeating: 0, count: rows * cols)
        var mineTypes: [MineType] = Array(repeating: .pointReduction, count: 5)
        mineTypes += Array(repeating: .pointTransfer, count: 4)
        mineTypes += Array(repeating: .letterLoss, count: 3)
        mineTypes += Array(repeating: .bonusCancel, count: 2)
        mineTypes += Array(repeating: .wordCancel, count: 2)

        mineTypes.shuffle()

        for type in mineTypes {
            var index: Int
            repeat {
                index = Int.random(in: 0..<rows * cols)
            } while board[index] != 0
            board[index] = type.rawValue
        }

        return board
    }

    // Ödül matrisi oluştur
    func generateRewardMatrix() -> [[Int]] {
        var matrix = Array(repeating: Array(repeating: 0, count: 15), count: 15)

        func placeReward(type: Int, count: Int) {
            var added = 0
            while added < count {
                let row = Int.random(in: 0..<15)
                let col = Int.random(in: 0..<15)
                if matrix[row][col] == 0 {
                    matrix[row][col] = type
                    added += 1
                }
            }
        }

        placeReward(type: RewardType.zoneBan.rawValue, count: 2)
        placeReward(type: RewardType.letterFreeze.rawValue, count: 3)
        placeReward(type: RewardType.extraMove.rawValue, count: 2)

        return matrix
    }

    // Firestore'a ödül matrisini kaydet
    func saveRewardMatrixToFirestore(gameId: String) {
        let db = Firestore.firestore()
        let matrix = generateRewardMatrix()
        let flatRewards = matrix.flatMap { $0 }

        db.collection("games").document(gameId).updateData([
            "rewards": flatRewards
        ]) { error in
            if let error = error {
                print("❌ Ödül matrisi Firestore'a yazılamadı: \(error.localizedDescription)")
            } else {
                print("✅ Ödül matrisi Firestore'a yazıldı.")
            }
        }
    }
    func createInitialLetterPool() -> [String] {
        var pool: [String] = []
        pool += Array(repeating: "A", count: 12)
        pool += Array(repeating: "B", count: 2)
        pool += Array(repeating: "C", count: 2)
        pool += Array(repeating: "Ç", count: 2)
        pool += Array(repeating: "D", count: 2)
        pool += Array(repeating: "E", count: 8)
        pool += Array(repeating: "F", count: 1)
        pool += Array(repeating: "G", count: 1)
        pool += Array(repeating: "Ğ", count: 1)
        pool += Array(repeating: "H", count: 1)
        pool += Array(repeating: "I", count: 4)
        pool += Array(repeating: "İ", count: 7)
        pool += Array(repeating: "J", count: 1)
        pool += Array(repeating: "K", count: 7)
        pool += Array(repeating: "L", count: 7)
        pool += Array(repeating: "M", count: 4)
        pool += Array(repeating: "N", count: 5)
        pool += Array(repeating: "O", count: 3)
        pool += Array(repeating: "Ö", count: 1)
        pool += Array(repeating: "P", count: 1)
        pool += Array(repeating: "R", count: 6)
        pool += Array(repeating: "S", count: 3)
        pool += Array(repeating: "Ş", count: 2)
        pool += Array(repeating: "T", count: 5)
        pool += Array(repeating: "U", count: 3)
        pool += Array(repeating: "Ü", count: 2)
        pool += Array(repeating: "V", count: 1)
        pool += Array(repeating: "Y", count: 2)
        pool += Array(repeating: "Z", count: 2)
        pool += Array(repeating: "*", count: 2) // JOKER

        return pool.shuffled()
    }
}
