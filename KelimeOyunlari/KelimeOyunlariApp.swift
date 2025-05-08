import SwiftUI
import FirebaseCore

@main
struct KelimeOyunlarıApp: App {
    @State private var isUserLoggedIn = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if isUserLoggedIn {
                GamePage() // Kullanıcı giriş yaptıysa oyun sayfasını aç
            } else {
                LoginView(isUserLoggedIn: $isUserLoggedIn) // Giriş yap ekranı
            }
            //GameBoardView() // Giriş kontrolü olmadan doğrudan açılır

        }
    }
}
