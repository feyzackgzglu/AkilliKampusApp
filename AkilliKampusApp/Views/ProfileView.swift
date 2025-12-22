import SwiftUI

struct ProfileView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var incidentManager: IncidentManager
    
    var body: some View {
        NavigationView {
            List {
                // Kullanıcı Bilgileri
                if let user = authManager.currentUser {
                    Section {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(user.role.rawValue) // Admin / User
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(user.role == .admin ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .foregroundColor(user.role == .admin ? .red : .blue)
                                    .cornerRadius(4)
                                
                                if let dept = user.department {
                                    Text(dept)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        
                        HStack {
                            Image(systemName: "envelope")
                            Text(user.email)
                                .foregroundColor(.gray)
                        }
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
        }
    }
}
