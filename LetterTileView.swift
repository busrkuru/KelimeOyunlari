import SwiftUI

struct LetterTileView: View {
    let letter: String
    let point: Int
    var isFrozen: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(isFrozen ? Color.gray.opacity(0.5) : Color.yellow)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isFrozen ? Color.blue : Color.black, lineWidth: 2)
                )

            Text(letter)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 4)
                .padding(.leading, 6)

            Text("\(point)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 4)
                .padding(.trailing, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            if isFrozen {
                Image(systemName: "snowflake")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.blue)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }
}
