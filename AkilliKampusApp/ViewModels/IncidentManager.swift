import Foundation
import Combine
import CoreLocation

class IncidentManager: ObservableObject {
    @Published var incidents: [Incident] = []
    
    // Filtreleme State'leri
    @Published var searchText: String = ""
    @Published var selectedFilterType: IncidentType? = nil
    @Published var showOnlyActive: Bool = false
    @Published var showOnlyFollowed: Bool = false
    
    init() {
        loadMockData()
    }
    
    // Filtrelenmiş Liste
    func filteredIncidents(for user: User?) -> [Incident] {
        return incidents.filter { incident in
            let matchesSearch = searchText.isEmpty || 
                                incident.title.localizedCaseInsensitiveContains(searchText) || 
                                incident.description.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedFilterType == nil || incident.type == selectedFilterType
            let matchesActive = !showOnlyActive || incident.status == .open
            let matchesFollowed = !showOnlyFollowed || (user?.followedIncidentIds.contains(incident.id) ?? false)
            
            return matchesSearch && matchesType && matchesActive && matchesFollowed
        }
        .sorted(by: { $0.dateReported > $1.dateReported })
    }
    
    func addIncident(type: IncidentType, title: String, description: String, location: CLLocationCoordinate2D, user: User) {
        let newIncident = Incident(
            id: UUID(),
            type: type,
            title: title,
            description: description,
            status: .open,
            dateReported: Date(),
            latitude: location.latitude,
            longitude: location.longitude,
            reporterId: user.id
        )
        incidents.insert(newIncident, at: 0)
    }
    
    // Durum Güncelleme
    func updateStatus(for incidentId: UUID, newStatus: IncidentStatus) {
        if let index = incidents.firstIndex(where: { $0.id == incidentId }) {
            incidents[index].status = newStatus
        }
    }
    
    // [YENİ] Açıklama Düzenleme (Admin)
    func updateDescription(for incidentId: UUID, newDescription: String) {
        if let index = incidents.firstIndex(where: { $0.id == incidentId }) {
            incidents[index].description = newDescription
        }
    }
    
    // [YENİ] Bildirim Silme (Admin/Uygunsuz)
    func deleteIncident(incidentId: UUID) {
        incidents.removeAll { $0.id == incidentId }
    }
    
    // Takip Et / Bırak
    func toggleFollow(for incident: Incident, user: inout User) {
        if user.followedIncidentIds.contains(incident.id) {
            user.followedIncidentIds.removeAll { $0 == incident.id }
        } else {
            user.followedIncidentIds.append(incident.id)
        }
    }
    
    private func loadMockData() {
        incidents = [
            Incident(
                id: UUID(),
                type: .technical,
                title: "Kütüphane Kliması Bozuk",
                description: "3. kat okuma salonundaki klima çok ses çıkarıyor ve soğutmuyor.",
                status: .open,
                dateReported: Date().addingTimeInterval(-3600),
                latitude: 41.0082,
                longitude: 28.9784,
                reporterId: "std_1"
            ),
            Incident(
                id: UUID(),
                type: .health,
                title: "Merdivenlerde Düşme Tehlikesi",
                description: "A blok girişindeki merdiven korkuluğu sallanıyor.",
                status: .investigating,
                dateReported: Date().addingTimeInterval(-86400),
                latitude: 41.0085,
                longitude: 28.9790,
                reporterId: "std_2"
            )
        ]
    }
}
