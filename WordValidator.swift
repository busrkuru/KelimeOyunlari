import Foundation

class WordValidator {
    static let shared = WordValidator()
    private var validWords: Set<String> = []

    private init() {
        loadWords()
    }

    private func loadWords() {
        if let path = Bundle.main.path(forResource: "turkce_kelime_listesi", ofType: "txt") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                let words = content.components(separatedBy: .newlines)
                validWords = Set(words.map { $0.uppercased() })
            } catch {
                print("Kelime listesi yüklenemedi: \(error)")
            }
        } else {
            print("turkce_kelime_listesi.txt bulunamadı.")
        }
    }

    func isValid(word: String) -> Bool {
        return validWords.contains(word.uppercased())
    }
}
