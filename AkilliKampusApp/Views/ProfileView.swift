import SwiftUI

struct ProfileView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var incidentManager: IncidentManager
    
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedDept = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Kullanıcı Bilgileri
                if let user = authManager.currentUser {
                    Section {
                        VStack(spacing: 20) {
                            HStack(spacing: 15) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    if isEditing {
                                        TextField("İsim Soyisim", text: $editedName)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                        
                                        TextField("Bölüm", text: $editedDept)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    } else {
                                        Text(user.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        if let dept = user.department {
                                            Text(dept)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Text(user.role.rawValue)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(user.role == .admin ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                        .foregroundColor(user.role == .admin ? .red : .blue)
                                        .cornerRadius(4)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            
                            if isEditing {
                                Button(action: saveProfile) {
                                    Text("Değişiklikleri Kaydet")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
                
                // Ayarlar
                if let user = authManager.currentUser {
                    Section(header: Text("Bildirim Ayarları")) {
                        ForEach(IncidentType.allCases) { type in
                            Toggle(isOn: Binding(
                                get: { user.notificationPreferences.contains(type.rawValue) },
                                set: { _ in authManager.toggleNotificationPreference(type: type) }
                            )) {
                                Label(type.rawValue, systemImage: type.iconName)
                            }
                        }
                    }
                }
                
                // Takip Edilenler
                if let user = authManager.currentUser, !user.followedIncidentIds.isEmpty {
                    Section(header: Text("Takip Ettiklerim")) {
                        ForEach(incidentManager.incidents.filter { user.followedIncidentIds.contains($0.id) }) { incident in
                            NavigationLink(destination: IncidentDetailView(incident: incident, manager: incidentManager, authManager: authManager)) {
                                HStack {
                                    Image(systemName: incident.type.iconName)
                                        .foregroundColor(incident.type.color)
                                    Text(incident.title)
                                }
                            }
                        }
                    }
                }
                
                // Çıkış Yap
                Section {
                    Button(action: {
                        authManager.logout()
                    }) {
                        Text("Çıkış Yap")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "İptal" : "Düzenle") {
                        if !isEditing {
                            if let user = authManager.currentUser {
                                editedName = user.name
                                editedDept = user.department ?? ""
                            }
                        }
                        isEditing.toggle()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
            }
        }
    }
    
    private func saveProfile() {
        authManager.updateProfile(name: editedName, department: editedDept) { error in
            if let error = error {
                alertMessage = "Hata: \(error.localizedDescription)"
            } else {
                alertMessage = "Profil başarıyla güncellendi!"
                isEditing = false
            }
            showingAlert = true
        }
    }
}
