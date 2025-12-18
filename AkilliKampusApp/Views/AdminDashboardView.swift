import SwiftUI

struct AdminDashboardView: View {
    @ObservedObject var manager: IncidentManager
    @State private var showEmergencyAlert = false
    @State private var emergencyMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Acil Durum Modülü
                Section(header: Text("Acil Durum Yönetimi")) {
                    Button(action: {
                        showEmergencyAlert = true
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red)
                                .clipShape(Circle())
                            
                            Text("Acil Duyuru Yayınla")
                                .foregroundColor(.red)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                // Bildirim Yönetimi
                Section(header: Text("Tüm Bildirimler")) {
                    ForEach(manager.incidents) { incident in
                        NavigationLink(destination: IncidentDetailView(incident: incident, manager: manager, authManager: AuthManager())) {
                            HStack {
                                Circle()
                                    .fill(incident.status.color)
                                    .frame(width: 10, height: 10)
                                VStack(alignment: .leading) {
                                    Text(incident.title)
                                        .font(.headline)
                                    Text(incident.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(incident.status.rawValue)
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yönetici Paneli")
            .sheet(isPresented: $showEmergencyAlert) {
                VStack(spacing: 20) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Acil Duyuru Gönder")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Bu mesaj tüm kullanıcılara anlık bildirim olarak gidecektir.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.gray)
                    
                    TextField("Duyuru Metni (Örn: Acil Tahliye)", text: $emergencyMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        // Mock send action
                        showEmergencyAlert = false
                        emergencyMessage = ""
                    }) {
                        Text("YAYINLA")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button("İptal") {
                        showEmergencyAlert = false
                    }
                    .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
}
