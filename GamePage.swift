import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GamePage: View {
    @State private var username = ""
    @State private var successRate: Double = 0.0
    @State private var totalGames = 0
    @State private var wonGames = 0
    @State private var selectedGameTime: String = ""
    
    @StateObject private var firestoreService = FirestoreService()
    @State private var isMatched = false
    
    @State private var checkMatchTimer: Timer? = nil
    @State private var currentUserId: String = ""
    
    
    @State private var matchedGameId: String?
    

    var body: some View {
        TabView {
            VStack {
                Text("Kullanıcı Adı: \(username)")
                    .font(.title)
                    .padding()

                Text("Başarı Yüzdesi: \(Int(successRate * 100))%")
                    .padding()

                Text("Yeni Oyun Seçiniz:")
                    .font(.title2)
                    .padding()

                Button("Hızlı Oyun (2 dakika)") {
                    selectedGameTime = "Hızlı Oyun (2 dakika)"
                    startNewGame(time: 2 * 60)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Hızlı Oyun (5 dakika)") {
                    selectedGameTime = "Hızlı Oyun (5 dakika)"
                    startNewGame(time: 5 * 60)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Genişletilmiş Oyun (12 saat)") {
                    selectedGameTime = "Genişletilmiş Oyun (12 saat)"
                    startNewGame(time: 12 * 60 * 60)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button("Genişletilmiş Oyun (24 saat)") {
                    selectedGameTime = "Genişletilmiş Oyun (24 saat)"
                    startNewGame(time: 24 * 60 * 60)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()
            }
            .tabItem {
                Label("Yeni Oyun", systemImage: "gamecontroller")
            }

            ActiveGamesView() // 🔁 Oyunu burada seçecek
                .tabItem {
                    Label("Aktif Oyunlar", systemImage: "gamecontroller")
                }

            FinishedGamesView()
                .tabItem {
                    Label("Biten Oyunlar", systemImage: "checkmark.circle")
                }
        }
        .onAppear {
            fetchUserData()
        }
    }

    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                username = data?["username"] as? String ?? "Bilinmiyor"
                totalGames = data?["totalGames"] as? Int ?? 0
                wonGames = data?["wonGames"] as? Int ?? 0

                if totalGames > 0 {
                    successRate = Double(wonGames) / Double(totalGames)
                }
            } else {
                print("User data not found")
            }
        }
    }

    
    func startNewGame(time: Int) {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let username = user.displayName ?? "Player"

        let gameQueueData: [String: Any] = [
            "gameTime": time,
            "userID": user.uid,
            "username": username,
            "status": "waiting",
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("gamesQueue").addDocument(data: gameQueueData) { error in
            if let error = error {
                print("❌ Kuyruğa ekleme hatası: \(error.localizedDescription)")
            } else {
                print("✅ Kuyruğa eklendi. Eşleşme kontrolü başlatılıyor...")

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    firestoreService.checkIfUserHasMatchedGame(uid: user.uid) { result in
                        switch result {
                        case .success(let gameId):
                            print("🎯 Eşleşme bulundu: \(gameId)")
                            self.matchedGameId = gameId
                            self.isMatched = true

                            // ✅ Mayınları oluştur ve Firestore'a yaz
                            let mines = firestoreService.generateMineBoard()
                            db.collection("games").document(gameId).updateData([
                                "mines": mines
                            ]) { error in
                                if let error = error {
                                    print("❌ Mayınlar Firestore'a eklenemedi: \(error.localizedDescription)")
                                } else {
                                    print("✅ Mayınlar Firestore'a başarıyla eklendi.")
                                }
                            }

                            // ✅ Ödülleri oluştur ve Firestore'a yaz
                            let rewardMatrix = firestoreService.generateRewardMatrix()
                            let flatRewards = rewardMatrix.flatMap { $0 }
                            db.collection("games").document(gameId).updateData([
                                "rewards": flatRewards
                            ]) { error in
                                if let error = error {
                                    print("❌ Ödüller Firestore'a eklenemedi: \(error.localizedDescription)")
                                } else {
                                    print("✅ Ödüller Firestore'a başarıyla eklendi.")
                                }
                            }

                            // ✅ Başlangıç harf havuzunu oluştur ve Firestore'a yaz
                            let initialPool = firestoreService.createInitialLetterPool()
                            db.collection("games").document(gameId).updateData([
                                "remainingPool": initialPool
                            ]) { error in
                                if let error = error {
                                    print("❌ Harf havuzu Firestore'a eklenemedi: \(error.localizedDescription)")
                                } else {
                                    print("✅ Harf havuzu başarıyla Firestore'a eklendi.")
                                }
                            }

                        case .failure(let error):
                            print("⚠️ Eşleşme yok: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    func startMatchCheckingLoop() {
        checkMatchTimer?.invalidate() // varsa eski timerı iptal et
        checkMatchTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            firestoreService.fetchActiveGame(for: currentUserId) { success in
                if success {
                    isMatched = true
                    checkMatchTimer?.invalidate() // eşleştiyse timer durdur
                }
            }
        }
    }

    func addPlayerToQueue(gameTime: Int) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let username = user.displayName ?? "Player"  // email yerine displayName kullanılacak

        let gameQueueData: [String: Any] = [
            "gameTime": gameTime,
            "userID": user.uid,
            "username": username,
            "status": "waiting",
            "timestamp": FieldValue.serverTimestamp() // sunucu zamanı eklendi
        ]

        db.collection("gamesQueue").addDocument(data: gameQueueData) { error in
            if let error = error {
                print("Oyuncu kuyruğa eklenemedi: \(error.localizedDescription)")
            } else {
                print("Oyuncu kuyruğa başarıyla eklendi.")
            }
        }
    }

    
}

struct GamePage_Previews: PreviewProvider {
    static var previews: some View {
        GamePage()
    }
}
