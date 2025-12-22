import SwiftUI

struct ContentView: View {
    @StateObject var authManager = AuthManager()
    @StateObject var incidentManager = IncidentManager()
    @StateObject var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            if authManager.isAuthenticated {
                // Giriş yapıldıysa Ana Ekran (Tab Bar)
                MainTabView(authManager: authManager, incidentManager: incidentManager, locationManager: locationManager)
            } else {
                // Giriş yapılmadıysa Login Ekranı
                LoginView(authManager: authManager)
            }
        }
        // [YENİ] Durum Güncelleme Bildirimi
        .alert(item: Binding<AlertItem?>(
            get: { incidentManager.statusUpdateMessage != nil ? AlertItem(message: incidentManager.statusUpdateMessage!) : nil },
            set: { _ in incidentManager.statusUpdateMessage = nil }
        )) { item in
            Alert(title: Text("Bildirim"), message: Text(item.message), dismissButton: .default(Text("Tamam")))
        }
        // [YENİ] Acil Durum Duyurusu (Overlay)
        .overlay(
            Group {
                if let msg = incidentManager.emergencyAlert {
                    VStack {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text("ACİL DUYURU")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(msg)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            Button("Anladım") {
                                incidentManager.emergencyAlert = nil
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(20)
                        }
                        .padding(30)
                        .background(Color.red)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                        .padding(40)
                        Spacer()
                    }
                    .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                }
            }
        )
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

// Helper for Alert with String
struct AlertItem: Identifiable {
    var id: String { message }
    let message: String
}

struct MainTabView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var incidentManager: IncidentManager
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        TabView {
            HomeView(incidentManager: incidentManager, authManager: authManager, locationManager: locationManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Ana Sayfa")
                }
            
            CampusMapView(manager: incidentManager, authManager: authManager, locationManager: locationManager)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Harita")
                }
            
            ReportIncidentView(manager: incidentManager, authManager: authManager, locationManager: locationManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Bildir")
                }
            
            if authManager.currentUser?.role == .admin {
                AdminDashboardView(manager: incidentManager, authManager: authManager)
                    .tabItem {
                        Image(systemName: "shield.lefthalf.filled")
                        Text("Yönetici")
                    }
            }
            
            ProfileView(authManager: authManager, incidentManager: incidentManager)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
        }
    }
}
