import Foundation
import CoreLocation
import SwiftUI

enum IncidentType: String, CaseIterable, Codable, Identifiable {
    case health = "Sağlık"
    case security = "Güvenlik"
    case technical = "Teknik Arıza"
    case environmental = "Çevre"
    case lostFound = "Kayıp/Buluntu"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .health: return "cross.case.fill"
        case .security: return "shield.fill"
        case .technical: return "wrench.and.screwdriver.fill"
        case .environmental: return "leaf.fill"
        case .lostFound: return "magnifyingglass"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return .red
        case .security: return .blue
        case .technical: return .orange
        case .environmental: return .green
        case .lostFound: return .purple
        }
    }
}

enum IncidentStatus: String, Codable, CaseIterable {
    case open = "Açık"
    case investigating = "İnceleniyor"
    case resolved = "Çözüldü"
    
    var color: Color {
        switch self {
        case .open: return .red
        case .investigating: return .orange
        case .resolved: return .green
        }
    }
}

struct Incident: Identifiable, Codable {
    let id: UUID
    let type: IncidentType
    var title: String
    var description: String
    var status: IncidentStatus
    let dateReported: Date
    var lastUpdated: Date
    let latitude: Double
    let longitude: Double
    let reporterId: String
    var imageUrl: String? = nil //Opsiyonel fotoğraf URL
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Broadcast: Identifiable, Codable {
    var id: String { documentId }
    let documentId: String
    let message: String
    let timestamp: Date
}
