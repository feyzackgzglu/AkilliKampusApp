import SwiftUI

struct HomeView: View {
    @ObservedObject var incidentManager: IncidentManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    
    // FAB için Sheet State Floating Action Button
    @State private var showReportSheet = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Filtre ve Arama Alanı
                    VStack(spacing: 10) {
                        TextField("Ara (Başlık veya Açıklama)...", text: $incidentManager.searchText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                FilterButton(title: "Tümü", isSelected: incidentManager.selectedFilterType == nil) {
                                    incidentManager.selectedFilterType = nil
                                }
                                
                                ForEach(IncidentType.allCases) { type in
                                    FilterButton(title: type.rawValue, isSelected: incidentManager.selectedFilterType == type) {
                                        incidentManager.selectedFilterType = type
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        HStack {
                            Toggle("Sadece Açık", isOn: $incidentManager.showOnlyActive)
                                .font(.caption)
                            Spacer()
                            if authManager.currentUser != nil {
                                Toggle("Takip Ettiklerim", isOn: $incidentManager.showOnlyFollowed)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                    
                    // Liste
                    List {
                        // [YENİ] Acil Duyuru Geçmişi
                        if !incidentManager.recentBroadcasts.isEmpty {
                            Section(header: Text("Son Duyurular").font(.caption).fontWeight(.bold).foregroundColor(.red)) {
                                ForEach(incidentManager.recentBroadcasts) { broadcast in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "megaphone.fill")
                                                .foregroundColor(.red)
                                            Text(broadcast.timestamp, style: .time)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(broadcast.timestamp, style: .date)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack {
                                            Text(broadcast.message)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if authManager.currentUser?.role == .admin {
                                                Button(action: {
                                                    incidentManager.deleteBroadcast(broadcastId: broadcast.documentId)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .font(.caption)
                                                        .foregroundColor(.red.opacity(0.7))
                                                        .padding(4)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }

                        Section(header: Text("Bildirim Akışı").font(.caption).fontWeight(.bold).foregroundColor(.gray)) {
                            ForEach(incidentManager.filteredIncidents(for: authManager.currentUser)) { incident in
                                NavigationLink(destination: IncidentDetailView(incident: incident, manager: incidentManager, authManager: authManager)) {
                                    IncidentListRow(incident: incident)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Floating Action Button (FAB)
                Button(action: {
                    showReportSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4, x: 0, y: 4)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bildirim Akışı").font(.headline)
                }
            }
            .sheet(isPresented: $showReportSheet) {
                 // Sheet içinde kendi Navigation'ı olan ReportIncidentView açılır
                 ReportIncidentView(manager: incidentManager, authManager: authManager, locationManager: locationManager)
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct IncidentListRow: View {
    let incident: Incident
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: incident.type.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(incident.type.color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(incident.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(incident.lastUpdated, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(incident.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(incident.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(incident.status.color.opacity(0.2))
                        .foregroundColor(incident.status.color)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}
