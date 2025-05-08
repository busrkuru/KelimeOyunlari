
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GameBoardView: View {
   let rows = 15
   let columns = 15
   var gameId: String

    @State private var boardLetters: [[String]] = Array(repeating: Array(repeating: "", count: 15), count: 15)
    @State private var playerLetters: [String] = []
    @State private var currentWord: String = ""
    @State private var currentWordScore: Int = 0
    @State private var wordValidityColor: Color = .black
    @State private var placedLetters: [(row: Int, col: Int, letter: String)] = []
    @State private var currentTurnUserId: String = ""
    //@State private var timeRemaining = 30
    //@State private var timer: Timer?
    @State private var isGameFinished = false
    @State private var gameStatus: String = "active"
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var remainingLetterCount: Int = 0
    @State private var playerDisplayName: String = ""
    @State private var myScore: Int = 0
    @State private var opponentScore: Int = 0
    @State private var myDisplayName: String = "Ben"
    @State private var opponentDisplayName: String = "?"
    @State private var mineWarningMessage: String? = nil
    @State private var showMineAlert: Bool = false
    @State private var isConfirming = false
    @State private var mineMatrix: [[Int]] = Array(repeating: Array(repeating: 0, count: 15), count: 15)
    @State private var rewardMatrix: [[Int]] = Array(repeating: Array(repeating: 0, count: 15), count: 15)
    @State private var activeRewards: [Int] = []  // 1: Bölge Yasağı, 2: Harf Yasağı, 3: Ekstra Hamle
    @State private var isExtraMoveActive: Bool = false
    @State private var rewardExplanationId: Int? = nil
    @State private var regionBan: [String: Any]? = nil
    @State private var frozenLetters: [String] = []
    @State private var isMoveModeActive = false
    @State private var selectedLetterToMove: (row: Int, col: Int)? = nil
    
   let letterPoints: [String: Int] = [
       "A": 1, "B": 3, "C": 4, "Ç": 4, "D": 3, "E": 1, "F": 7,
       "G": 5, "Ğ": 8, "H": 5, "I": 2, "İ": 1, "J": 10, "K": 1,
       "L": 1, "M": 2, "N": 1, "O": 2, "Ö": 7, "P": 5, "R": 1,
       "S": 2, "Ş": 4, "T": 1, "U": 2, "Ü": 3, "V": 7, "Y": 3,
       "Z": 4, "*": 0
   ]

   let specialCells: [String: [(Int, Int)]] = [
       "H2": [(0,5), (0,9), (1,6), (1,8), (5,0), (5,5), (5,9), (5,14),
              (6,1), (6,6), (6,8), (6,13), (8,1), (8,6), (8,8), (8,13),
              (9,0), (9,5), (9,9), (9,14), (13,6), (13,8), (14,5), (14,9)],
       "H3": [(1,1), (1,13), (4,4), (4,10), (10,4), (10,10), (13,1), (13,13)],
       "K2": [(2,7), (3,3), (3,11), (7,2), (7,12), (11,3), (11,11), (12,7)],
       "K3": [(0,2), (0,12), (2,0), (2,14), (12,0), (12,14), (14,2), (14,12)],
       "Orta": [(7,7)]
   ]
    
    
    var body: some View {
        VStack {
            // ✅ Üst Skor Çubuğu
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text("\(myScore)").foregroundColor(.black).bold()
                    Text(myDisplayName).foregroundColor(.black).bold()
                }

                Spacer()

                Text("🟡 \(remainingLetterCount)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.black)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(opponentScore)").foregroundColor(.black).bold()
                    Text(opponentDisplayName).foregroundColor(.black).bold()
                }
            }
            .padding()
            .background(Color.white)
            .padding(.horizontal)

            // ✅ Diğer Bilgiler
            Text("Kelime: \(currentWord)").foregroundColor(wordValidityColor).fontWeight(.bold)
            Text("Puan: \(currentWordScore)").foregroundColor(wordValidityColor)
            Text("Süre: \(timeRemaining)").foregroundColor(.red).fontWeight(.bold)

            // ✅ Oyun Tahtası
            VStack(spacing: 2) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<columns, id: \.self) { col in
                            let cellType = getCellType(row: row, col: col)
                            ZStack {
                                Rectangle()
                                    .fill(colorForCell(type: cellType))
                                    .frame(width: 24, height: 24)
                                    .border(Color.gray)
                                    .onDrop(of: [.text], isTargeted: nil) { providers in
                                        guard !isGameFinished else { return false }
                                        guard Auth.auth().currentUser?.uid == currentTurnUserId else { return false }

                                        // Region Ban kontrolü
                                        if let ban = regionBan,
                                           ban["target"] as? String == Auth.auth().currentUser?.uid,
                                           let side = ban["allowedSide"] as? String {

                                            let isRightSide = col >= 7
                                            let isLeftSide = col < 7

                                            if (side == "right" && isLeftSide) || (side == "left" && isRightSide) {
                                                print("❌ Yasaklı bölgeye harf koyamazsın.")
                                                return false
                                            }
                                        }

                                        if let provider = providers.first {
                                            _ = provider.loadObject(ofClass: String.self) { string, _ in
                                                if let letter = string {
                                                    DispatchQueue.main.async {
                                                        // ❄️ Harf yasağı kontrolü
                                                        if frozenLetters.contains(letter) {
                                                            print("🧊 Bu harf donmuş: \(letter)")
                                                            return
                                                        }

                                                        // ✅ Oyuncunun elinde o harf var mı kontrolü
                                                        guard let index = playerLetters.firstIndex(of: letter) else {
                                                            print("❌ Oyuncunun bu harfi yok: \(letter)")
                                                            return
                                                        }

                                                        // 🧩 Harfi tahtaya yerleştir
                                                        boardLetters[row][col] = letter
                                                        placedLetters.append((row, col, letter))
                                                        playerLetters.remove(at: index)

                                                        saveBoardToFirestore()
                                                        drawNewLettersFromRemainingPool()

                                                        // 🎁 Ödül kontrolü
                                                        let rewardType = rewardMatrix[row][col]
                                                        if rewardType != 0 {
                                                            activeRewards.append(rewardType)
                                                            rewardMatrix[row][col] = 0
                                                            print("🎁 Ödül alındı: \(rewardType)")
                                                        }

                                                        evaluateLastPlacedLetter()
                                                    }
                                                }
                                            }
                                            return true
                                        }
                                        return false
                                    }

                                if !boardLetters[row][col].isEmpty {
                                    Text(boardLetters[row][col]).foregroundColor(.black).bold()
                                } else if let label = labelForCell(type: cellType) {
                                    Text(label).font(.system(size: 8)).foregroundColor(.white)
                                }
                                
                                
                            }
                            .onTapGesture {
                                guard isMoveModeActive, Auth.auth().currentUser?.uid == currentTurnUserId else { return }

                                if let selected = selectedLetterToMove {
                                    // İkinci tıklama: taşıma yapılacak yer
                                    let (fromRow, fromCol) = selected
                                    let dx = abs(fromRow - row)
                                    let dy = abs(fromCol - col)

                                    // Sadece 1 birim komşuya ve boş kutuya taşıma
                                    if dx + dy == 1 && boardLetters[row][col].isEmpty {
                                        let letter = boardLetters[fromRow][fromCol]
                                        boardLetters[fromRow][fromCol] = ""
                                        boardLetters[row][col] = letter
                                        selectedLetterToMove = nil
                                        isMoveModeActive = false
                                        saveBoardToFirestore()
                                        switchTurn()
                                        evaluateLastPlacedLetter() // <-- bunu ekle

                                    }
                                } else {
                                    // İlk tıklama: harf olan hücre seçimi
                                    if !boardLetters[row][col].isEmpty {
                                        selectedLetterToMove = (row, col)
                                    }
                                }
                            }
                            
                            
                        }
                    }
                }
            }

            // ✅ Oyuncu Harfleri
            /*
            HStack(spacing: 8) {
                ForEach(playerLetters, id: \.self) { letter in
                    Text(letter)
                        .frame(width: 35, height: 35)
                        .background(Color.yellow)
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black))
                        .onDrag {
                            NSItemProvider(object: letter as NSString)
                        }
                }
            }
             */
            // 🎁 ÖDÜLLER BÖLÜMÜ
            if !activeRewards.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(activeRewards, id: \.self) { reward in
                            Button(action: {
                                switch reward {
                                case 1:
                                    activateRegionBan()
                                case 2:
                                    activateLetterBan()
                                case 3:
                                    activateExtraMove()
                                default:
                                    break
                                }
                                removeReward(type: reward)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: iconForRewardType(reward))
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding(6)
                                        .background(Color.orange)
                                        .cornerRadius(6)

                                    Text(fullLabelForRewardType(reward))
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            HStack(spacing: 8) {
                ForEach(playerLetters, id: \.self) { letter in
                    LetterTileView(
                        letter: letter,
                        point: letterPoints[letter] ?? 0,
                        isFrozen: frozenLetters.contains(letter) // ❄️ Harf dondurulmuşsa vurgula
                    )
                    .onDrag {
                        NSItemProvider(object: letter as NSString)
                    }
                }
            }

            // ✅ Onayla Butonu
           

            VStack(spacing: 12) {
                    Button("Onayla") {
                        guard !isGameFinished, !isConfirming else { return }
                        isConfirming = true
                        confirmWordAndSwitchTurn()
                    }
                    .disabled(isGameFinished || isConfirming || Auth.auth().currentUser?.uid != currentTurnUserId)
                    .padding()
                    .background(isGameFinished || isConfirming || Auth.auth().currentUser?.uid != currentTurnUserId ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    HStack(spacing: 12) {
                        Button("Pas Geç") {
                            passTurn()
                        }
                        .disabled(isGameFinished || Auth.auth().currentUser?.uid != currentTurnUserId)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Teslim Ol") {
                            surrenderGame()
                        }
                        .disabled(isGameFinished || Auth.auth().currentUser?.uid != currentTurnUserId)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Harf Taşı") {
                            isMoveModeActive.toggle()
                            selectedLetterToMove = nil
                        }
                        .disabled(isGameFinished || Auth.auth().currentUser?.uid != currentTurnUserId)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(isMoveModeActive ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 4)
                .padding(.bottom, 16)
            }
        .padding()
        .onAppear {
            fetchGameData()
            listenToBoardChanges()
            listenToLetters()
            listenToTurn()
            listenToRemainingPool()
            listenToScores()
            listenToMines()
            listenToRewards()
            listenToRegionBan()
            listenToLetterBan()
        }
        .alert(isPresented: $showMineAlert) {
            Alert(title: Text("🧨 Mayın Etkisi"), message: Text(mineWarningMessage ?? ""), dismissButton: .default(Text("Tamam")))
        }
    }
     
    
    func switchTurn() {
        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String else { return }

            let nextTurn = (myUid == player1Id) ? player2Id : player1Id

            gameRef.updateData([
                "turn": nextTurn,
                "turnStartAt": FieldValue.serverTimestamp()
            ]) { err in
                if let err = err {
                    print("❌ Sıra geçişi hatası: \(err.localizedDescription)")
                } else {
                    print("🔁 Sıra rakibe geçti.")
                }
            }
        }
    }
    
    //pas geç
    func passTurn() {
        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String else {
                print("❌ Oyuncu ID'leri alınamadı.")
                return
            }

            let nextTurn = (myUid == player1Id) ? player2Id : player1Id
            var newConsecutivePasses = (data["consecutivePasses"] as? Int ?? 0) + 1

            if newConsecutivePasses >= 2 {
                let scoreMap = data["scores"] as? [String: Int] ?? [:]
                let p1Score = scoreMap[player1Id] ?? 0
                let p2Score = scoreMap[player2Id] ?? 0

                let winner: String = {
                    if p1Score > p2Score { return player1Id }
                    else if p2Score > p1Score { return player2Id }
                    else { return "draw" }
                }()

                gameRef.updateData([
                    "gameStatus": "finished",
                    "winner": winner,
                    "consecutivePasses": 0 // sıfırla
                ]) { err in
                    if let err = err {
                        print("❌ Oyun bitirme hatası: \(err.localizedDescription)")
                    } else {
                        print("🏁 Arka arkaya 2 pas, oyun bitti.")
                        DispatchQueue.main.async {
                            self.isGameFinished = true
                        }
                    }
                }
            } else {
                gameRef.updateData([
                    "turn": nextTurn,
                    "turnStartAt": FieldValue.serverTimestamp(),
                    "consecutivePasses": newConsecutivePasses
                ]) { err in
                    if let err = err {
                        print("❌ Pas geçme hatası: \(err.localizedDescription)")
                    } else {
                        print("🔄 Pas geçildi, sıra geçti.")
                        DispatchQueue.main.async {
                            self.placedLetters.removeAll()
                            self.currentWord = ""
                            self.currentWordScore = 0
                        }
                    }
                }
            }
        }
    }
    //teslim ol
    func surrenderGame() {
        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String else {
                print("❌ Oyuncu ID'leri alınamadı.")
                return
            }

            let winnerId = (myUid == player1Id) ? player2Id : player1Id

            gameRef.updateData([
                "gameStatus": "finished",
                "winner": winnerId
            ]) { err in
                if let err = err {
                    print("❌ Teslim olma hatası: \(err.localizedDescription)")
                } else {
                    print("🏳️ Oyuncu teslim oldu, oyun sona erdi.")
                    DispatchQueue.main.async {
                        self.isGameFinished = true
                    }
                }
            }
        }
    }
    //harf taşı
    func moveLetter(from: (Int, Int), to: (Int, Int)) {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to

        guard boardLetters[toRow][toCol].isEmpty else {
            print("❌ Hedef hücre dolu.")
            return
        }

        let letter = boardLetters[fromRow][fromCol]
        boardLetters[fromRow][fromCol] = ""
        boardLetters[toRow][toCol] = letter

        saveBoardToFirestore()

        // Sıra geçişi
        confirmWordAndSwitchTurn()
    }
    
    func listenToTurn() {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let turnId = data["turn"] as? String else {
                return
            }

            DispatchQueue.main.async {
                if lastTurnId != turnId {
                    lastTurnId = turnId
                    currentTurnUserId = turnId
                }

                // ✅ İlk hamle yapılmamışsa ve 1 saat geçmişse oyunu bitir
                if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
                   let board = data["board"] as? [String] {
                    let elapsedSeconds = Int(Date().timeIntervalSince(createdAt))
                    let isEmptyBoard = board.allSatisfy { $0.isEmpty }

                    if isEmptyBoard && elapsedSeconds >= 3600 {
                        print("⏰ 1 saat içinde ilk hamle yapılmadı.")
                        endGameDueToNoMove(board: board, data: data)
                    }
                }
            }
        }
    }

    func fullLabelForRewardType(_ reward: Int) -> String {
        switch reward {
        case 1: return "Bölge Yasağı"
        case 2: return "Harf Yasağı"
        case 3: return "Ekstra Hamle"
        default: return "Ödül"
        }
    }
    
    func listenToLetterBan() {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let freezeMap = data["frozenLetters"] as? [String: [String]],
                  let myUid = Auth.auth().currentUser?.uid else {
                self.frozenLetters = []
                return
            }

            DispatchQueue.main.async {
                self.frozenLetters = freezeMap[myUid] ?? []
            }
        }
    }
    
    
    func listenToRegionBan() {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let regionBanData = data["regionBan"] as? [String: Any],
                  let expiresAt = regionBanData["expiresAt"] as? Timestamp else {
                self.regionBan = nil
                return
            }

            // Süre kontrolü
            let now = Date()
            if expiresAt.dateValue() > now {
                DispatchQueue.main.async {
                    self.regionBan = regionBanData
                }
            } else {
                // Süresi geçmişse ban'ı kaldır
                DispatchQueue.main.async {
                    self.regionBan = nil
                }
            }
        }
    }
    
    func removeReward(type: Int) {
        if let index = activeRewards.firstIndex(of: type) {
            activeRewards.remove(at: index)
        }
    }

    func iconForRewardType(_ reward: Int) -> String {
        switch reward {
        case 1: return "location.north.line"      // Bölge yasağı
        case 2: return "nosign"                   // Harf yasağı
        case 3: return "arrow.triangle.2.circlepath" // Ekstra hamle
        default: return "gift"
        }
    }
    
    func labelForRewardType(_ reward: Int) -> String {
        switch reward {
        case 1: return "R"
        case 2: return "H"
        case 3: return "E"
        default: return "?"
        }
    }
    func activateRegionBan() {
        print("🏁 Rakip sadece belirli bölgeye harf koyabilir")

        guard let myId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        // Rakip ID'yi Firestore'dan çek
        gameRef.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let player1Id = data["player1Id"] as? String,
               let player2Id = data["player2Id"] as? String {

                let opponentId = (myId == player1Id) ? player2Id : player1Id

                let update: [String: Any] = [
                    "regionBan": [
                        "target": opponentId,
                        "allowedSide": "right", // veya "left"
                        "expiresAt": FieldValue.serverTimestamp()
                    ]
                ]

                gameRef.updateData(update) { err in
                    if let err = err {
                        print("❌ Region ban yazılamadı: \(err.localizedDescription)")
                    } else {
                        print("✅ Region ban aktif edildi.")
                        // Ödülü kaldır
                        if let index = activeRewards.firstIndex(of: 1) {
                            activeRewards.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    func activateLetterBan() {
        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, _ in
            guard let data = snapshot?.data(),
                  let lettersMap = data["letters"] as? [String: [String]],
                  let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String else { return }

            // Rakip UID'sini belirle
            let opponentId = (myUid == player1Id) ? player2Id : player1Id

            guard let opponentLetters = lettersMap[opponentId], !opponentLetters.isEmpty else { return }

            let frozen = Array(opponentLetters.shuffled().prefix(2))

            // Firestore'a yaz
            gameRef.updateData([
                "frozenLetters.\(opponentId)": frozen
            ]) { err in
                if let err = err {
                    print("❌ Dondurma hatası: \(err.localizedDescription)")
                } else {
                    print("⛔ Rakibin dondurulan harfleri: \(frozen)")
                }
            }
        }

        // Ödülü kaldır
        if let index = activeRewards.firstIndex(of: 2) {
            activeRewards.remove(at: index)
        }
    }
    func activateExtraMove() {
        print("🔄 Ekstra hamle hakkı kazandın")
        isExtraMoveActive = true // bu flag bir kez daha onaylamaya izin verir
        if let index = activeRewards.firstIndex(of: 3) {
            activeRewards.remove(at: index)
        }
    }
    func listenToRewards() {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let flatRewards = data["rewards"] as? [Int] else { return }

            DispatchQueue.main.async {
                self.rewardMatrix = stride(from: 0, to: flatRewards.count, by: 15).map {
                    Array(flatRewards[$0..<min($0 + 15, flatRewards.count)])
                }
            }
        }
    }
    func listenToMines() {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let flatMines = data["mines"] as? [Int] else { return }

            DispatchQueue.main.async {
                self.mineMatrix = stride(from: 0, to: flatMines.count, by: 15).map {
                    Array(flatMines[$0..<min($0 + 15, flatMines.count)])
                }
            }
        }
    }
    
    func listenToRemainingPool() {
        let db = Firestore.firestore()
        let docRef = db.collection("games").document(gameId)

        docRef.addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let pool = data["remainingPool"] as? [String] else {
                return
            }

            DispatchQueue.main.async {
                self.remainingLetterCount = pool.count
            }
        }
    }
    enum MineType: Int {
        case pointReduction = 1   // %30 puan
        case pointTransfer = 2    // puan rakibe aktarılır
        case letterLoss = 3       // elindeki harfler havuza verilir
        case bonusCancel = 4      // çarpanlar iptal
        case wordCancel = 5       // kelime iptal edilir
    }
    func confirmWordAndSwitchTurn() {
        guard let myUid = Auth.auth().currentUser?.uid else {
            print("❌ Kullanıcı oturumu yok.")
            isConfirming = false
            return
        }

        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Doküman alınamadı: \(error.localizedDescription)")
                isConfirming = false
                return
            }

            guard let data = snapshot?.data() else {
                print("❌ Veri alınamadı.")
                isConfirming = false
                return
            }

            guard let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String else {
                print("❌ Oyuncu ID'leri eksik.")
                isConfirming = false
                return
            }

            let nextTurn: String
            if isExtraMoveActive {
                nextTurn = myUid  // sıra yine kendisine geçsin
                isExtraMoveActive = false  // hakkı kullandı, sıfırla
                print("🔁 Ekstra hamle hakkı kullanıldı, sıra tekrar sende!")
            } else {
                nextTurn = (myUid == player1Id) ? player2Id : player1Id
            }
            var finalScore = currentWordScore
            var warningMessages: [String] = []
            
            var updates: [String: Any] = [
                "turn": nextTurn,
                "turnStartAt": FieldValue.serverTimestamp(),
                "consecutivePasses": 0 // pas sayacını sıfırla
            ]

            for (row, col, _) in placedLetters {
                let mineValue = mineMatrix[row][col]
                if let type = MineType(rawValue: mineValue) {
                    switch type {
                    case .pointReduction:
                        let reduced = Int(Double(finalScore) * 0.3)
                        finalScore = reduced
                        warningMessages.append("💣 Puan Bölünmesi: Puan %30'a düşürüldü.")
                    case .pointTransfer:
                        finalScore = 0
                        warningMessages.append("💣 Puan Transferi: Puanın rakibe aktarıldı.")
                        updates["scores.\(nextTurn)"] = FieldValue.increment(Int64(currentWordScore))
                    case .letterLoss:
                        warningMessages.append("💣 Harf Kaybı: Elindeki harfler sıfırlandı ve yenileri çekilecek.")
                        if let uid = Auth.auth().currentUser?.uid {
                            gameRef.updateData(["letters.\(uid)": []]) { err in
                                if err == nil {
                                    DispatchQueue.main.async {
                                        self.playerLetters = []
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        drawNewLettersFromFirestore(count: 7)
                                    }
                                }
                            }
                        }
                    case .bonusCancel:
                        warningMessages.append("💣 Çarpanlar İptal: Kelime çarpanları iptal edildi.")
                    case .wordCancel:
                        finalScore = 0
                        warningMessages.append("💣 Kelime İptali: Puan alamayacaksın.")
                    }
                }
            }

            // 🔽 Skor ekle
            if wordValidityColor == .green, finalScore > 0 {
                updates["scores.\(myUid)"] = FieldValue.increment(Int64(finalScore))
                print("✅ \(finalScore) puan eklendi.")
            } else {
                print("❌ Geçersiz kelime veya sıfır puan.")
            }
            // 🔓 Karşı oyuncunun harf donması sıfırlanır
            let clearFrozenLettersKey = "frozenLetters.\(nextTurn)"
            //updates[clearFrozenLettersKey] = FieldValue.delete()
            
            var steppedMineEffects: [String] = []
            var didStepOnMine = false

            for (row, col, _) in placedLetters {
                let mineValue = mineMatrix[row][col]
                if let type = MineType(rawValue: mineValue) {
                    didStepOnMine = true
                    switch type {
                    case .pointReduction:
                        steppedMineEffects.append("Puan Bölünmesi")
                    case .pointTransfer:
                        steppedMineEffects.append("Puan Transferi")
                    case .letterLoss:
                        steppedMineEffects.append("Harf Kaybı")
                    case .bonusCancel:
                        steppedMineEffects.append("Çarpan İptali")
                    case .wordCancel:
                        steppedMineEffects.append("Kelime İptali")
                    }
                }
            }

            if didStepOnMine {
                updates["steppedOnMine.\(myUid)"] = true
                updates["mineEffects.\(myUid)"] = FieldValue.arrayUnion(steppedMineEffects)
            }
            // Firestore güncelle
            gameRef.updateData(updates) { err in
                if let err = err {
                    print("❌ Güncelleme hatası: \(err.localizedDescription)")
                } else {
                    print("✅ Sıra başarıyla \(nextTurn) oyuncusuna geçti.")
                }

                // Sıfırla
                DispatchQueue.main.async {
                    self.placedLetters.removeAll()
                    self.currentWord = ""
                    self.currentWordScore = 0
                    self.isConfirming = false
                    self.checkIfGameShouldEnd() // ✅

                }
            }

            // Uyarıları göster
            if !warningMessages.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.mineWarningMessage = warningMessages.joined(separator: "\n")
                    self.showMineAlert = true
                }
            }
        }
        
    }
    
    func saveBoardToFirestore() {
        let flatBoard = boardLetters.flatMap { $0 }
        let db = Firestore.firestore()
        db.collection("games").document(gameId).updateData([
            "board": flatBoard
        ]) { error in
            if let error = error {
                print("❌ Tahta Firestore'a kaydedilemedi: \(error.localizedDescription)")
            } else {
                print("✅ Tahta Firestore'a kaydedildi.")
            }
        }
    }

   func updateBoardInFirestore() {
       let flatBoard = boardLetters.flatMap { $0 }
       let db = Firestore.firestore()
       db.collection("games").document(gameId).updateData(["board": flatBoard])
   }

   func listenToBoardChanges() {
       let db = Firestore.firestore()
       db.collection("games").document(gameId).addSnapshotListener { snapshot, error in
           guard let data = snapshot?.data(), let flatBoard = data["board"] as? [String] else { return }
           DispatchQueue.main.async {
               self.boardLetters = stride(from: 0, to: 225, by: 15).map {
                   Array(flatBoard[$0..<min($0 + 15, flatBoard.count)])
               }
           }
       }
   }
    func fetchGameData() {
        let db = Firestore.firestore()
        db.collection("games").document(gameId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {

                // 🧩 Tahta
                if let flatBoard = data["board"] as? [String] {
                    self.boardLetters = stride(from: 0, to: 225, by: 15).map {
                        Array(flatBoard[$0..<min($0 + 15, flatBoard.count)])
                    }
                }

                // 🎲 Oyuncu harfleri
                if let userId = Auth.auth().currentUser?.uid,
                   let lettersMap = data["letters"] as? [String: [String]],
                   let myLetters = lettersMap[userId] {
                    self.playerLetters = myLetters
                }

                // 🔤 Oyuncu adları
                if let player1Id = data["player1Id"] as? String,
                   let player2Id = data["player2Id"] as? String,
                   let currentUid = Auth.auth().currentUser?.uid {

                    if currentUid == player1Id {
                        self.myDisplayName = "Ben"
                        fetchDisplayName(for: player2Id) { name in self.opponentDisplayName = name }
                    } else {
                        self.myDisplayName = "Ben"
                        fetchDisplayName(for: player1Id) { name in self.opponentDisplayName = name }
                    }
                }

                // 🔢 Kalan harf sayısı
                if let pool = data["remainingPool"] as? [String] {
                    DispatchQueue.main.async {
                        self.remainingLetterCount = pool.count
                    }
                }

                // ⏳ Süreyi başlat
                if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
                   let gameTime = data["gameTime"] as? Int {
                    let elapsed = Int(Date().timeIntervalSince(createdAt))
                    DispatchQueue.main.async {
                        self.timeRemaining = max(0, gameTime - elapsed)
                        startCountdownTimer()
                    }
                }

                // 🏅 Skorları al
                if let scoreMap = data["scores"] as? [String: Int],
                   let uid = Auth.auth().currentUser?.uid {
                    self.myScore = scoreMap[uid] ?? 0
                    let opponentId = scoreMap.keys.first(where: { $0 != uid }) ?? ""
                    self.opponentScore = scoreMap[opponentId] ?? 0
                }
            }
        }
    }
    func fetchDisplayName(for uid: String, completion: @escaping (String) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let name = data["username"] as? String {
                completion(name)
            } else {
                completion("Bilinmiyor")
            }
        }
    }
    func startCountdownTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                finishGame()
            }
        }
    }
/*
   func fetchGameData() {
       let db = Firestore.firestore()
       db.collection("games").document(gameId).getDocument { snapshot, _ in
           if let data = snapshot?.data() {
               if let flatBoard = data["board"] as? [String] {
                   self.boardLetters = stride(from: 0, to: 225, by: 15).map {
                       Array(flatBoard[$0..<min($0 + 15, flatBoard.count)])
                   }
               }

               if let userId = Auth.auth().currentUser?.uid,
                  let lettersMap = data["letters"] as? [String: [String]],
                  let myLetters = lettersMap[userId] {
                   self.playerLetters = myLetters
               }
           }
       }
   }
    */
   func getCellType(row: Int, col: Int) -> String? {
       for (type, positions) in specialCells {
           if positions.contains(where: { $0 == (row, col) }) {
               return type
           }
       }
       return nil
   }

   func colorForCell(type: String?) -> Color {
       switch type {
       case "H2": return .blue
       case "H3": return .purple
       case "K2": return .green
       case "K3": return .brown
       case "Orta": return .orange
       default: return .gray.opacity(0.3)
       }
   }

   func labelForCell(type: String?) -> String? {
       switch type {
       case "H2": return "H2"
       case "H3": return "H3"
       case "K2": return "K2"
       case "K3": return "K3"
       case "Orta": return "★"
       default: return nil
       }
   }

   func evaluateLastPlacedLetter() {
       guard let last = placedLetters.last else { return }
       let (row, col, _) = last
       let horizontal = extractWord(row: row, col: col, direction: (0, 1))
       let vertical = extractWord(row: row, col: col, direction: (1, 0))
       let best = horizontal.word.count >= vertical.word.count ? horizontal : vertical
       currentWord = best.word
       currentWordScore = best.score
       validateWord(best.word)
   }
    
    func extractWord(row: Int, col: Int, direction: (Int, Int)) -> (word: String, score: Int) {
        var r = row, c = col
        while r - direction.0 >= 0 && c - direction.1 >= 0 &&
              r - direction.0 < rows && c - direction.1 < columns &&
              !boardLetters[r - direction.0][c - direction.1].isEmpty {
            r -= direction.0
            c -= direction.1
        }

        var word = "", score = 0, multiplier = 1
        var usedBonusCancel = false

        // 🔍 Mayınlardan biri "bonusCancel" ise, bunu kontrol et
        for (rCheck, cCheck, _) in placedLetters {
            if mineMatrix[rCheck][cCheck] == MineType.bonusCancel.rawValue {
                usedBonusCancel = true
                break
            }
        }

        while r < rows && c < columns && !boardLetters[r][c].isEmpty {
            let letter = boardLetters[r][c]
            var letterScore = letterPoints[letter] ?? 0
            word.append(letter)

            if !usedBonusCancel {
                if specialCells["H2"]?.contains(where: { $0 == (r, c) }) == true { letterScore *= 2 }
                if specialCells["H3"]?.contains(where: { $0 == (r, c) }) == true { letterScore *= 3 }
                if specialCells["K2"]?.contains(where: { $0 == (r, c) }) == true { multiplier *= 2 }
                if specialCells["K3"]?.contains(where: { $0 == (r, c) }) == true { multiplier *= 3 }
            }

            score += letterScore
            r += direction.0
            c += direction.1
        }

        return (word, score * multiplier)
    }

   /*
    func extractWord(row: Int, col: Int, direction: (Int, Int)) -> (word: String, score: Int) {
       var r = row, c = col
       while r - direction.0 >= 0 && c - direction.1 >= 0 &&
             r - direction.0 < rows && c - direction.1 < columns &&
             !boardLetters[r - direction.0][c - direction.1].isEmpty {
           r -= direction.0
           c -= direction.1
       }

       var word = "", score = 0, multiplier = 1
       while r < rows && c < columns && !boardLetters[r][c].isEmpty {
           let letter = boardLetters[r][c]
           var letterScore = letterPoints[letter] ?? 0

           if specialCells["H2"]?.contains(where: { $0 == (r, c) }) == true { letterScore *= 2 }
           if specialCells["H3"]?.contains(where: { $0 == (r, c) }) == true { letterScore *= 3 }
           if specialCells["K2"]?.contains(where: { $0 == (r, c) }) == true { multiplier *= 2 }
           if specialCells["K3"]?.contains(where: { $0 == (r, c) }) == true { multiplier *= 3 }

           word.append(letter)
           score += letterScore
           r += direction.0
           c += direction.1
       }
       return (word, score * multiplier)
   }
    */

   func validateWord(_ word: String) {
       guard let path = Bundle.main.path(forResource: "turkce_kelime_listesi", ofType: "txt"),
             let content = try? String(contentsOfFile: path) else {
           print("❌ Kelime listesi bulunamadı")
           wordValidityColor = .black
           return
       }
       let allWords = Set(content.components(separatedBy: .newlines).map { $0.uppercased() })
       wordValidityColor = allWords.contains(word.uppercased()) ? .green : .red
   }
   func drawNewLettersFromFirestore(count: Int) {
       let db = Firestore.firestore()
       let docRef = db.collection("games").document(gameId)

       db.runTransaction({ (transaction, errorPointer) -> Any? in
           let snapshot: DocumentSnapshot
           do {
               snapshot = try transaction.getDocument(docRef)
           } catch let fetchError as NSError {
               errorPointer?.pointee = fetchError
               return nil
           }

           guard var pool = snapshot.data()?["remainingPool"] as? [String],
                 var letterMap = snapshot.data()?["letters"] as? [String: [String]],
                 let uid = Auth.auth().currentUser?.uid else {
               return nil
           }

           let drawCount = min(count, pool.count)
           let newLetters = Array(pool.prefix(drawCount))
           pool.removeFirst(drawCount)

           var myLetters = letterMap[uid] ?? []
           myLetters.append(contentsOf: newLetters)

           letterMap[uid] = myLetters

           transaction.updateData([
               "remainingPool": pool,
               "letters": letterMap
           ], forDocument: docRef)

           return nil
       }) { (_, error) in
           if let error = error {
               print("❌ Harf çekme hatası: \(error.localizedDescription)")
           } else {
               print("✅ Harf çekildi ve Firestore güncellendi.")
           }
       }
   }
   func listenToLetters() {
       let db = Firestore.firestore()
       let docRef = db.collection("games").document(gameId)

       docRef.addSnapshotListener { snapshot, error in
           guard let data = snapshot?.data(),
                 let uid = Auth.auth().currentUser?.uid,
                 let lettersMap = data["letters"] as? [String: [String]],
                 let myLetters = lettersMap[uid] else {
               return
           }

           DispatchQueue.main.async {
               self.playerLetters = myLetters
           }
       }
   }
    func listenToScores() {
        let db = Firestore.firestore()
        let docRef = db.collection("games").document(gameId)

        docRef.addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data(),
                  let scores = data["scores"] as? [String: Int],
                  let myUid = Auth.auth().currentUser?.uid else {
                return
            }

            DispatchQueue.main.async {
                self.myScore = scores[myUid] ?? 0
                let opponentId = scores.keys.first(where: { $0 != myUid }) ?? ""
                self.opponentScore = scores[opponentId] ?? 0
            }
        }
    }
    func fetchPlayerLetters() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("games").document(gameId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let lettersMap = data["letters"] as? [String: [String]],
               let myLetters = lettersMap[userId] {
                playerLetters = myLetters
            }
        }
    }
    @State private var lastTurnId: String?

   
    func finishGame() {
        isGameFinished = true
        timer?.invalidate()

        let db = Firestore.firestore()
        db.collection("games").document(gameId).updateData([
            "gameStatus": "finished"
        ]) { err in
            if let err = err {
                print("❌ Oyun bitirme hatası: \(err.localizedDescription)")
            } else {
                print("🏁 Oyun sona erdi.")
            }
        }
    }
    /*func resetTimerIfMyTurn() {
        timer?.invalidate()
        
        guard Auth.auth().currentUser?.uid == currentTurnUserId else { return }

        timeRemaining = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                timer?.invalidate()
                //autoSwitchTurn()
            }
        }
    }
     */
    /*
    func autoSwitchTurn() {
        guard let myUid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String else { return }

            let nextTurn = (myUid == player1Id) ? player2Id : player1Id

            gameRef.updateData(["turn": nextTurn, "turnStartAt": FieldValue.serverTimestamp()]) { err in
                if let err = err {
                    print("❌ Otomatik sıra geçişi başarısız: \(err.localizedDescription)")
                } else {
                    print("⏱ Süre doldu, sıra otomatik olarak geçti.")
                }
            }
        }
    }
     */
    func drawNewLettersFromRemainingPool() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        // 1️⃣ Oyuncunun zaten yeterince harfi varsa ekleme
        guard playerLetters.count < 7 else {
            print("⚠️ Zaten maksimum harf sayısına sahipsin.")
            return
        }

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  var pool = data["remainingPool"] as? [String] else { return }

            // 2️⃣ Havuz boşsa harf çekme
            guard !pool.isEmpty else {
                print("⚠️ Harf havuzu boş, çekilebilecek harf kalmadı.")
                return
            }

            let newLetter = pool.removeFirst()
            playerLetters.append(newLetter)

            gameRef.updateData([
                "letters.\(userId)": playerLetters,
                "remainingPool": pool
            ]) { err in
                if let err = err {
                    print("❌ Güncelleme hatası: \(err.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.remainingLetterCount = pool.count
                        self.checkIfGameShouldEnd() // ✅

                    }
                }
            }
        }
    }
    func createMines(for gameId: String) {
        let db = Firestore.firestore()
        var flatMines = Array(repeating: 0, count: 225)

        // Mayın türleri ve adetleri
        let mineTypes: [Int: Int] = [
            1: 5, // Puan Bölünmesi
            2: 4, // Puan Transferi
            3: 3, // Harf Kaybı
            4: 2, // Ekstra Hamle Engeli (bonusCancel)
            5: 2  // Kelime İptali
        ]

        var usedIndices: Set<Int> = []

        for (type, count) in mineTypes {
            var placed = 0
            while placed < count {
                let index = Int.random(in: 0..<225)
                if !usedIndices.contains(index) {
                    flatMines[index] = type
                    usedIndices.insert(index)
                    placed += 1
                }
            }
        }

        db.collection("games").document(gameId).updateData([
            "mines": flatMines
        ]) { error in
            if let error = error {
                print("❌ Mayınlar yazılamadı: \(error.localizedDescription)")
            } else {
                print("🧨 Mayınlar başarıyla yerleştirildi.")
            }
        }
    }
    
    func checkIfGameShouldEnd() {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let gameRef = db.collection("games").document(gameId)

        gameRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let player1Id = data["player1Id"] as? String,
                  let player2Id = data["player2Id"] as? String,
                  let lettersMap = data["letters"] as? [String: [String]],
                  let scoresMap = data["scores"] as? [String: Int] else {
                print("❌ Oyun verileri eksik.")
                return
            }

            let player1Letters = lettersMap[player1Id] ?? []
            let player2Letters = lettersMap[player2Id] ?? []

            let player1Score = scoresMap[player1Id] ?? 0
            let player2Score = scoresMap[player2Id] ?? 0

            // Oyunculardan birinin elinde harf kalmadıysa
            if player1Letters.isEmpty || player2Letters.isEmpty {
                var updatedScores = scoresMap
                var winnerId = ""
                
                if player1Letters.isEmpty && !player2Letters.isEmpty {
                    // Player 1 bitirdi, Player 2'nin harf puanları ona eklenir, Player 2'den düşülür
                    let penalty = player2Letters.reduce(0) { $0 + (letterPoints[$1] ?? 0) }
                    updatedScores[player1Id] = player1Score + penalty
                    updatedScores[player2Id] = max(0, player2Score - penalty)
                } else if player2Letters.isEmpty && !player1Letters.isEmpty {
                    let penalty = player1Letters.reduce(0) { $0 + (letterPoints[$1] ?? 0) }
                    updatedScores[player2Id] = player2Score + penalty
                    updatedScores[player1Id] = max(0, player1Score - penalty)
                }

                // Kazananı belirle
                if updatedScores[player1Id] == updatedScores[player2Id] {
                    winnerId = "draw"
                } else {
                    winnerId = updatedScores[player1Id]! > updatedScores[player2Id]! ? player1Id : player2Id
                }

                // Firestore'a yaz
                gameRef.updateData([
                    "scores": updatedScores,
                    "gameStatus": "finished",
                    "winner": winnerId
                ]) { err in
                    if let err = err {
                        print("❌ Oyun bitirme hatası: \(err.localizedDescription)")
                    } else {
                        print("🏁 Oyun sona erdi. Kazanan: \(winnerId)")
                        DispatchQueue.main.async {
                            self.isGameFinished = true
                        }
                    }
                }
            }
        }
    }
    func endGameDueToNoMove(board: [String], data: [String: Any]) {
        guard let player1Id = data["player1Id"] as? String,
              let player2Id = data["player2Id"] as? String,
              let currentTurn = data["turn"] as? String else {
            return
        }

        let loserId = currentTurn
        let winnerId = (loserId == player1Id) ? player2Id : player1Id

        let db = Firestore.firestore()
        db.collection("games").document(gameId).updateData([
            "gameStatus": "finished",
            "winner": winnerId,
            "reason": "noFirstMove"
        ]) { err in
            if let err = err {
                print("❌ Oyun bitirilemedi (ilk hamle yapılmadı): \(err.localizedDescription)")
            } else {
                print("🏁 Oyun sona erdi: \(loserId) hamle yapmadı.")
                DispatchQueue.main.async {
                    self.isGameFinished = true
                }
            }
        }
    }
}
