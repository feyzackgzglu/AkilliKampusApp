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
        // [REVAMPED] Acil Durum Duyurusu (Premium Glassmorphic Overlay)
        .overlay(
            ZStack {
                if let msg = incidentManager.emergencyAlert {
                    // Glassmorphic Full Screen Background
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 25) {
                        // Header Icon with Glow
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .symbolRenderingMode(.multicolor)
                                .foregroundStyle(.white)
                                .shadow(color: .red.opacity(0.5), radius: 10)
                        }
                        
                        VStack(spacing: 8) {
                            Text("ACİL DUYURU")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .tracking(2)
                                .foregroundColor(.white)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 80, height: 2)
                        }
                        
                        Text(msg)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                incidentManager.emergencyAlert = nil
                            }
                        }) {
                            Text("Anladım")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                        }
                        .padding(.top, 10)
                    }
                    .padding(35)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color(red: 0.6, green: 0, blue: 0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 20)
                    )
                    .padding(30)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: incidentManager.emergencyAlert)
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
