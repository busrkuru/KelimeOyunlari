import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @Binding var isUserLoggedIn: Bool  // Binding ile isUserLoggedIn'i ana ekrana bağlıyoruz.
    @State private var showRegisterView = false // Kayıt olma ekranını göstermek için

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Giriş Yap")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("E-posta", text: $email)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 5)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)

                SecureField("Şifre", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 5)

                Button(action: {
                    loginUser()
                }) {
                    Text("Giriş Yap")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                Text(errorMessage)
                    .foregroundColor(.red)

                if isLoggedIn {
                    Text("Giriş Başarılı!")
                        .foregroundColor(.green)
                }

                Button(action: {
                    showRegisterView.toggle() // Kayıt olma ekranını aç
                }) {
                    Text("Kayıt Ol")
                        .foregroundColor(.blue)
                        .underline() // Altını çizebiliriz
                }
                .padding()
                .fullScreenCover(isPresented: $showRegisterView) {
                    RegisterView() // Kayıt olma ekranını göster
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all))
            .navigationBarBackButtonHidden(true)  // Geri butonunu gizle
        }
    }

    func loginUser() {
        // Şifre geçerlilik kontrolü
        let passwordRegex = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$")
        guard passwordRegex.evaluate(with: password) else {
            errorMessage = "Şifre en az 8 karakter, bir büyük harf, bir küçük harf ve bir rakam içermelidir."
            return
        }

        // Firebase ile giriş
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                updateDisplayName(newName: email)
                isLoggedIn = true
                isUserLoggedIn = true
                errorMessage = ""
            }
        }
    }
    func updateDisplayName(newName: String) {
        guard let user = Auth.auth().currentUser else { return }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { error in
            if let error = error {
                print("Kullanıcı adı güncellenemedi: \(error.localizedDescription)")
            } else {
                print("Kullanıcı adı başarıyla güncellendi.")
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isUserLoggedIn: .constant(false))
    }
}
