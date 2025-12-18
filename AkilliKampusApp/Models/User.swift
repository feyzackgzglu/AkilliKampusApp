import Foundation

enum UserRole: String, Codable {
    case user = "User"
    case admin = "Admin"
}

struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var department: String? // Birim (Öğrenci İşleri, Mimarlık Fak. vb.)
    var role: UserRole
    var followedIncidentIds: [UUID] = [] // Takip edilen bildirim ID'leri
    
    // Mock Users
    static let mockUser = User(
        id: "user_001",
        name: "Ali Veli",
        email: "ali@kampus.edu.tr",
        department: "Bilgisayar Müh.",
        role: .user,
        followedIncidentIds: []
    )
    
    static let mockAdmin = User(
        id: "admin_001",
        name: "Güvenlik Merkezi",
        email: "guvenlik@kampus.edu.tr",
        department: "Güvenlik Birimi",
        role: .admin,
        followedIncidentIds: []
    )
}
