import SwiftUI

struct ForgotPasswordSimulationView: View {
    @Environment(\.dismiss) var dismiss
    let email: String
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step = 1 // 1: Code entry, 2: New password entry
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                if !isSuccess {
                    VStack(spacing: 8) {
                        Image(systemName: step == 1 ? "envelope.badge.shield.half.filled" : "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.vertical)
                        
                        Text(step == 1 ? "Doğrulama Kodu Gönderildi" : "Yeni Şifre Belirle")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if step == 1 {
                            Text("\(email) adresine 6 haneli bir doğrulama kodu gönderilmiştir.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    if step == 1 {
                        VStack(alignment: .leading) {
                            Text("Doğrulama Kodu")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("000000", text: $code)
                                .keyboardType(.numberPad)
                                .font(.title)
                                .tracking(10)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            withAnimation { step = 2 }
                        }) {
                            Text("Kodu Doğrula")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(code.count >= 4 ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(code.count < 4)
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 15) {
                            SecureField("Yeni Şifre", text: $newPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            SecureField("Yeni Şifre (Yeniden)", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            withAnimation { isSuccess = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }) {
                            Text("Şifreyi Güncelle")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(newPassword.count >= 6 && newPassword == confirmPassword ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(newPassword.count < 6 || newPassword != confirmPassword)
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Şifreniz Başarıyla Güncellendi")
                            .font(.headline)
                        
                        Text("Giriş ekranına yönlendiriliyorsunuz...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .transition(.scale)
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

struct ForgotPasswordSimulationView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordSimulationView(email: "test@atauni.edu.tr")
    }
}
