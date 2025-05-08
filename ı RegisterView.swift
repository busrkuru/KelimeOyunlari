import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false

    var body: some View {
        VStack {
            TextField("Kullanıcı Adı", text: $username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("E-posta", text: $email)
                .padding()
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Şifre", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Kayıt Ol") {
                registerUser()
            }
            .padding()
            
            Text(errorMessage)
                .foregroundColor(.red)
            
            if isRegistered {
                Text("Kayıt Başarılı!")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }

    func registerUser() {
        // E-posta ve şifre ile Firebase'e kullanıcı kaydını yap
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                isRegistered = true
                errorMessage = ""
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
