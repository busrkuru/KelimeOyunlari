import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false
    @Environment(\.presentationMode) var presentationMode  // Geri gitmek için
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Kayıt Ol")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Kullanıcı Adı", text: $username)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 5)
                
                TextField("E-posta", text: $email)
                    .padding()
                    .keyboardType(.emailAddress)
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 5)
                
                SecureField("Şifre", text: $password)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 5)
                
                Button(action: {
                    registerUser()
                }) {
                    Text("Kayıt Ol")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
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
            .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all))
            .navigationBarBackButtonHidden(false) // Geri butonunu görünür
            .navigationBarItems(leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()  // Geri gitme
            }) {
                Text("Geri")
                    .foregroundColor(.blue)
            })
        }
    }
    
    func registerUser() {
        // Şifre geçerlilik kontrolü
        let passwordRegex = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$")
        guard passwordRegex.evaluate(with: password) else {
            errorMessage = "Şifre en az 8 karakter, bir büyük harf, bir küçük harf ve bir rakam içermelidir."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(result!.user.uid)

                userRef.setData([
                    "username": username,
                    "email": email
                ]) { error in
                    if let error = error {
                        errorMessage = "Kullanıcı adı veritabanına kaydedilemedi: \(error.localizedDescription)"
                    } else {
                        isRegistered = true
                        errorMessage = ""
                    }
                }
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
