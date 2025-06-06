import UIKit
import Firebase

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase'i başlat
        FirebaseApp.configure()
        return true
    }

    // Diğer AppDelegate metodları (istenirse eklenebilir)
}
