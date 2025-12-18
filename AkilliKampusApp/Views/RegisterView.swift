import SwiftUI

struct RegisterView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var email = ""
    @State private var department = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $name)
                    TextField("E-posta", text: $email)
                        .autocapitalization(.none)
                    TextField("Birim / Bölüm", text: $department)
                }
                
                Section(header: Text("Güvenlik")) {
                    SecureField("Şifre", text: $password)
                }
                
                Section {
                    Button(action: {
                        authManager.register(name: name, email: email, department: department, password: password)
                    }) {
                        Text("Kayıt Ol")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }
                
                if let error = authManager.authError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                }
            }
            .navigationTitle("Yeni Kayıt")
            .navigationBarItems(leading: Button("İptal") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

