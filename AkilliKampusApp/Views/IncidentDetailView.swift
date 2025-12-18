import SwiftUI
import MapKit

struct IncidentDetailView: View {
    let incident: Incident
    @ObservedObject var manager: IncidentManager
    @ObservedObject var authManager: AuthManager
    
    @State private var selectedStatus: IncidentStatus
    // Edit Mode states
    @State private var isEditing = false
    @State private var editedDescription = ""
    @Environment(\.presentationMode) var presentationMode
    
    var isFollowing: Bool {
        guard let user = authManager.currentUser else { return false }
        return user.followedIncidentIds.contains(incident.id)
    }
    
    init(incident: Incident, manager: IncidentManager, authManager: AuthManager) {
        self.incident = incident
        self.manager = manager
        self.authManager = authManager
        _selectedStatus = State(initialValue: incident.status)
        _editedDescription = State(initialValue: incident.description)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Konum Önizleme (Mini Harita)
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: incident.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                )), annotationItems: [incident]) { item in
                    MapMarker(coordinate: item.coordinate, tint: item.type.color)
                }
                .frame(height: 200)
                .cornerRadius(12)
                
                // Başlık ve Durum
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(incident.type.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(incident.type.color.opacity(0.1))
                            .foregroundColor(incident.type.color)
                        Spacer()
                        Text(selectedStatus.rawValue)
                            .font(.caption)
                            .foregroundColor(selectedStatus.color)
                    }
                    Text(incident.title).font(.title).fontWeight(.bold)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Açıklama (Düzenlenebilir)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Açıklama").font(.headline)
                        Spacer()
                        // Admin için Düzenle Butonu
                        if authManager.currentUser?.role == .admin {
                            Button(action: {
                                if isEditing {
                                    // Save changes
                                    manager.updateDescription(for: incident.id, newDescription: editedDescription)
                                }
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Kaydet" : "Düzenle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if isEditing {
                        TextEditor(text: $editedDescription)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    } else {
                        Text(incident.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Role Based Actions
                if let user = authManager.currentUser {
                    if user.role == .admin {
                        VStack(spacing: 15) {
                            // Durum Güncelle
                            VStack(alignment: .leading) {
                                Text("Durum Güncelle").font(.headline)
                                Picker("Durum", selection: $selectedStatus) {
                                    ForEach(IncidentStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: selectedStatus) { newValue in
                                    manager.updateStatus(for: incident.id, newStatus: newValue)
                                }
                            }
                            
                            // Silme Butonu
                            Button(action: {
                                manager.deleteIncident(incidentId: incident.id)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Bildirimi Sil / Sonlandır")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        
                    } else {
                        // User: Takip Et
                        Button(action: {
                            if var currentUser = authManager.currentUser {
                                manager.toggleFollow(for: incident, user: &currentUser)
                                authManager.currentUser = currentUser
                            }
                        }) {
                            HStack {
                                Image(systemName: isFollowing ? "bell.slash.fill" : "bell.fill")
                                Text(isFollowing ? "Takibi Bırak" : "Bildirimi Takip Et")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFollowing ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Detay")
        .navigationBarTitleDisplayMode(.inline)
    }
}
