import Foundation
import Combine
import CoreLocation
import FirebaseFirestore

class IncidentManager: ObservableObject {
    @Published var incidents: [Incident] = []
    
    // filtreleme State'leri
    @Published var searchText: String = ""
    @Published var selectedFilterType: IncidentType? = nil
    @Published var showOnlyActive: Bool = false
    @Published var showOnlyFollowed: Bool = false
    
    // bildirim sistemleri ama yeni
    @Published var emergencyAlert: String? = nil
    @Published var recentBroadcasts: [Broadcast] = []
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
            .limit(to: 10) // Son 10 duyuruyu çek
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let allBroadcasts = documents.compactMap { doc -> Broadcast? in
                    let data = doc.data()
                    if let message = data["message"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp {
                        return Broadcast(documentId: doc.documentID, message: message, timestamp: timestamp.dateValue())
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    // 24 saat içindeki duyuruları filtrele
                    self?.recentBroadcasts = allBroadcasts.filter { 
                        abs($0.timestamp.timeIntervalSinceNow) < 86400 
                    }
                    
                    // En sonuncusu için anlık pop-up göster (eğer son 5 dakika içindeyse)
                    if let latest = allBroadcasts.first,
                       abs(latest.timestamp.timeIntervalSinceNow) < 300 {
                        if self?.emergencyAlert != latest.message {
                            self?.emergencyAlert = latest.message
                        }
                    }
                }
            }
    }
    
    // real-time listener for incidents
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
                    
                    let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp
                    let id = UUID(uuidString: doc.documentID) ?? UUID()
                    let imageUrl = data["imageUrl"] as? String
                    
                    let incident = Incident(
                        id: id,
                        type: type,
                        title: title,
                        description: description,
                        status: status,
                        dateReported: timestamp.dateValue(),
                        lastUpdated: lastUpdatedTimestamp?.dateValue() ?? timestamp.dateValue(),
                        latitude: latitude,
                        longitude: longitude,
                        reporterId: reporterId,
                        imageUrl: imageUrl
                    )

                    // durum Değişikliği Bildirimi Kontrolü
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
        // biz simülasyon olarak statusUpdateMessage set ediyoruz ve haptic veriyoruz.
        DispatchQueue.main.async {
            self.statusUpdateMessage = "'\(incident.title)' başlıklı bildirimin durumu '\(incident.status.rawValue)' olarak güncellendi."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func sendEmergencyBroadcast(message: String) {
        let broadcastData: [String: Any] = [
            "message": message,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("broadcasts").addDocument(data: broadcastData)
    }
    
    func deleteBroadcast(broadcastId: String) {
        db.collection("broadcasts").document(broadcastId).delete { error in
            if let error = error {
                print("Error deleting broadcast: \(error)")
            }
        }
    }
    
    // filtrelenmiş Liste
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
            (.health, "Revir Kapalı", "Kütüphane yanındaki revir şu an hizmet vermiyor.", 39.9020, 41.2445, "https://picsum.photos/seed/health/600/400"),
            (.security, "Aydınlatma Sorunu", "Yemekhane yolundaki sokak lambaları yanmıyor.", 39.9012, 41.2450, nil),
            (.technical, "Asansör Arızası", "Mühendislik binası B blok asansörü 3. katta kaldı.", 39.9016, 41.2442, "https://picsum.photos/seed/tech/600/400"),
            (.environmental, "Su Sızıntısı", "Spor salonu girişinde su sızıntısı var.", 39.9008, 41.2435, nil),
            (.technical, "Wi-Fi Bağlantı Sorunu", "Öğrenci merkezi bölgesinde eduroam bağlantısı kopuyor.", 39.9025, 41.2448, nil)
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
    
    
    func addIncident(type: IncidentType, title: String, description: String, location: CLLocationCoordinate2D, user: User, imageUrl: String? = nil, completion: @escaping (Error?) -> Void = { _ in }) {
        let id = UUID()
        let incidentData: [String: Any] = [
            "type": type.rawValue,
            "title": title,
            "description": description,
            "status": IncidentStatus.open.rawValue,
            "dateReported": Timestamp(date: Date()),
            "lastUpdated": Timestamp(date: Date()),
            "latitude": location.latitude,
            "longitude": location.longitude,
            "reporterId": user.id,
            "imageUrl": imageUrl as Any
        ]
        
        db.collection("incidents").document(id.uuidString).setData(incidentData) { error in
            if let error = error {
                print("Error adding incident: \(error)")
            }
            completion(error)
        }
    }
    
    // durum Güncelleme
    func updateStatus(for incidentId: UUID, newStatus: IncidentStatus) {
        db.collection("incidents").document(incidentId.uuidString).updateData([
            "status": newStatus.rawValue,
            "lastUpdated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating status: \(error)")
            }
        }
    }
    
    // açıklama Düzenleme (admin)
    func updateDescription(for incidentId: UUID, newDescription: String) {
        db.collection("incidents").document(incidentId.uuidString).updateData([
            "description": newDescription,
            "lastUpdated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating description: \(error)")
            }
        }
    }
    
    // bildirim Silme (admin)
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
