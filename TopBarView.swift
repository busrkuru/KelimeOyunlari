import SwiftUI

struct TopBarView: View {
    var username: String
    var score: Int
    var remainingLetters: Int
    var opponentUsername: String
    var opponentScore: Int

    var body: some View {
        HStack {
            // Sol taraf: Kullanıcı adı ve skor
            VStack(alignment: .leading) {
                Text(username)
                    .font(.headline)
                Text("Skor: \(score)")
                    .font(.subheadline)
            }
            Spacer()
            
            // Orta: Kalan harf
            VStack {
                Text("Kalan Harf")
                    .font(.subheadline)
                Text("\(remainingLetters)")
                    .font(.title2)
                    .bold()
            }
            Spacer()
            
            // Sağ taraf: Rakip adı ve skor
            VStack(alignment: .trailing) {
                Text(opponentUsername)
                    .font(.headline)
                Text("Skor: \(opponentScore)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}

struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopBarView(username: "Ben", score: 10, remainingLetters: 85, opponentUsername: "Rakip", opponentScore: 8)
    }
}
