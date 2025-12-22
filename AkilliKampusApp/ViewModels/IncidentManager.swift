import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

class IncidentManager: ObservableObject {
    @Published var incidents: [Incident] = []
    
    // Filtreleme State'leri
    @Published var searchText: String = ""
    @Published var selectedFilterType: IncidentType? = nil
    @Published var showOnlyActive: Bool = false
    @Published var showOnlyFollowed: Bool = false
    
    // [YENİ] Bildirim Sistemleri
    @Published var emergencyAlert: String? = nil
    @Published var statusUpdateMessage: String? = nil
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var broadcastListener: ListenerRegistration?
    private var lastKnownStatuses: [UUID: IncidentStatus] = [:]

    init() {
        startListeningForIncidents()
        startListeningForBroadcasts()
    }
    
    deinit {
        listenerRegistration?.remove()
        broadcastListener?.remove()
    }

    private func startListeningForBroadcasts() {
        broadcastListener = db.collection("broadcasts")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let document = snapshot?.documents.first else { return }
                let data = document.data()
                if let message = data["message"] as? String,
                   let timestamp = data["timestamp"] as? Timestamp {
                    // Sadece son 1 dakika içinde atılan mesajları göster
                    if abs(timestamp.dateValue().timeIntervalSinceNow) < 60 {
                        DispatchQueue.main.async {
                            self?.emergencyAlert = message
                        }
                    }
                }
            }
    }
    
    // Real-time listener for incidents
    private func startListeningForIncidents() {
        listenerRegistration = db.collection("incidents")
            .order(by: "dateReported", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening for incidents: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.incidents = documents.compactMap { doc -> Incident? in
                    let data = doc.data()
                    
                    // Manual Decoding for safer mapping from Firestore
                    guard let typeString = data["type"] as? String,
                          let type = IncidentType(rawValue: typeString),
                          let statusString = data["status"] as? String,
                          let status = IncidentStatus(rawValue: statusString),
                          let title = data["title"] as? String,
                          let description = data["description"] as? String,
                          let timestamp = data["dateReported"] as? Timestamp,
                          let latitude = data["latitude"] as? Double,
                          let longitude = data["longitude"] as? Double,
                          let reporterId = data["reporterId"] as? String else {
                        return nil
                    }
                    
                    let id = UUID(uuidString: doc.documentID) ?? UUID()
                    let imageUrl = data["imageUrl"] as? String
                    
                    let incident = Incident(
                        id: id,
                        type: type,
                        title: title,
                        description: description,
                        status: status,
                        dateReported: timestamp.dateValue(),
                        latitude: latitude,
                        longitude: longitude,
                        reporterId: reporterId,
                        imageUrl: imageUrl
                    )

                    // Durum Değişikliği Bildirimi Kontrolü
                    if let oldStatus = self?.lastKnownStatuses[id], oldStatus != status {
                        self?.notifyStatusChange(for: incident)
                    }
                    self?.lastKnownStatuses[id] = status
                    
                    return incident
                }
            }
    }
    
    private func notifyStatusChange(for incident: Incident) {
        // Gerçekte burada Push Notification gider.
        // Biz simülasyon olarak statusUpdateMessage set ediyoruz.
        DispatchQueue.main.async {
            self.statusUpdateMessage = "'\(incident.title)' başlıklı bildirimin durumu '\(incident.status.rawValue)' olarak güncellendi."
        }
    }

    func sendEmergencyBroadcast(message: String) {
        let broadcastData: [String: Any] = [
            "message": message,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("broadcasts").addDocument(data: broadcastData)
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
    }
    
    func seedSampleData(user: User) {
        let sampleData: [(IncidentType, String, String, Double, Double, String?)] = [
            (.health, "Revir Kapalı", "Kütüphane yanındaki revir şu an hizmet vermiyor.", 39.9020, 41.2470, "https://picsum.photos/seed/health/600/400"),
            (.security, "Aydınlatma Sorunu", "Yemekhane yolundaki sokak lambaları yanmıyor.", 39.9010, 41.2490, nil),
            (.technical, "Asansör Arızası", "Mühendislik binası B blok asansörü 3. katta kaldı.", 39.9030, 41.2460, "https://picsum.photos/seed/tech/600/400"),
            (.environmental, "Su Sızıntısı", "Spor salonu girişinde su sızıntısı var.", 39.9000, 41.2480, nil),
            (.technical, "Wi-Fi Bağlantı Sorunu", "Öğrenci merkezi bölgesinde eduroam bağlantısı kopuyor.", 39.9015, 41.2485, nil)
        ]
        
        for data in sampleData {
            addIncident(
                type: data.0,
                title: data.1,
                description: data.2,
                location: CLLocationCoordinate2D(latitude: data.3, longitude: data.4),
                user: user,
                imageUrl: data.5
            )
        }
    }
    
    func addIncident(type: IncidentType, title: String, description: String, location: CLLocationCoordinate2D, user: User, imageUrl: String? = nil) {
        let id = UUID()
        let incidentData: [String: Any] = [
            "type": type.rawValue,
            "title": title,
            "description": description,
            "status": IncidentStatus.open.rawValue,
            "dateReported": Timestamp(date: Date()),
            "latitude": location.latitude,
            "longitude": location.longitude,
            "reporterId": user.id,
            "imageUrl": imageUrl as Any
        ]
        
        db.collection("incidents").document(id.uuidString).setData(incidentData) { error in
            if let error = error {
                print("Error adding incident: \(error)")
            }
        }
    }
    
    // Durum Güncelleme
    func updateStatus(for incidentId: UUID, newStatus: IncidentStatus) {
        db.collection("incidents").document(incidentId.uuidString).updateData([
            "status": newStatus.rawValue
        ]) { error in
            if let error = error {
                print("Error updating status: \(error)")
            }
        }
    }
    
    // Açıklama Düzenleme (Admin)
    func updateDescription(for incidentId: UUID, newDescription: String) {
        db.collection("incidents").document(incidentId.uuidString).updateData([
            "description": newDescription
        ]) { error in
            if let error = error {
                print("Error updating description: \(error)")
            }
        }
    }
    
    // Bildirim Silme (Admin/Uygunsuz)
    func deleteIncident(incidentId: UUID) {
        db.collection("incidents").document(incidentId.uuidString).delete { error in
            if let error = error {
                print("Error deleting incident: \(error)")
            }
        }
    }
    
    // Takip Et / Bırak (User modelinde olduğu için manager üzerinden tetiklenmesi yetmeyebilir, Firestore'da user dokümanı güncellenmeli)
    func toggleFollow(for incident: Incident, user: User, completion: @escaping (Error?) -> Void) {
        var updatedFollowedIds = user.followedIncidentIds
        if updatedFollowedIds.contains(incident.id) {
            updatedFollowedIds.removeAll { $0 == incident.id }
        } else {
            updatedFollowedIds.append(incident.id)
        }
        
        let idStrings = updatedFollowedIds.map { $0.uuidString }
        
        db.collection("users").document(user.id).updateData([
            "followedIncidentIds": idStrings
        ]) { error in
            completion(error)
        }
    }
}
