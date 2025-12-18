import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showForgotPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.columns.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.bottom, 40)
            
            Text("Akıllı Kampüs")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("E-posta Adresi", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Şifre", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            if let error = authManager.authError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                authManager.login(email: email, password: password)
            }) {
                Text("Giriş Yap")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button("Şifremi Unuttum") {
                showForgotPassword = true
            }
            .alert(isPresented: $showForgotPassword) {
                Alert(title: Text("Şifre Sıfırlama"), message: Text("adresi e-postanıza bağlantı gönderildi."), dismissButton: .default(Text("Tamam")))
            }
            
            Spacer()
            
                
            Button(action: {
                authManager.signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Google ile Giriş Yap")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }
            .padding(.horizontal)

            HStack {
                Text("Hesabın yok mu?")
                Button("Kayıt Ol") {
                    showRegister = true
                }
            }
            .padding(.bottom)
        }
        .padding()
        .sheet(isPresented: $showRegister) {
            RegisterView(authManager: authManager)
        }
    }
}
