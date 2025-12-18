import SwiftUI

struct ContentView: View {
    @StateObject var authManager = AuthManager()
    @StateObject var incidentManager = IncidentManager()
    
    var body: some View {
        if authManager.isAuthenticated {
            // Giriş yapıldıysa Ana Ekran (Tab Bar)
            MainTabView(authManager: authManager, incidentManager: incidentManager)
        } else {
            // Giriş yapılmadıysa Login Ekranı
            LoginView(authManager: authManager)
        }
    }
}

struct MainTabView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var incidentManager: IncidentManager
    
    var body: some View {
        TabView {
            HomeView(incidentManager: incidentManager, authManager: authManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Ana Sayfa")
                }
            
            CampusMapView(manager: incidentManager)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Harita")
                }
            
            ReportIncidentView(manager: incidentManager, authManager: authManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Bildir")
                }
            
            if authManager.currentUser?.role == .admin {
                AdminDashboardView(manager: incidentManager)
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
