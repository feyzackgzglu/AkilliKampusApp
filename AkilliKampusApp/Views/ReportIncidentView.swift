import SwiftUI
import CoreLocation
import MapKit

struct ReportIncidentView: View {
    @ObservedObject var manager: IncidentManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: IncidentType = .technical
    @State private var showAlert = false
    @State private var attachPhoto = false
    
    // Harita Bölgesi (Varsayılan: Kampüs Merkezi)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9013, longitude: 41.2482),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Kullanıcı haritayı hareket ettirdi mi?
    @State private var userHasMovedMap = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Olay Detayları")) {
                    Picker("Tür", selection: $selectedType) {
                        ForEach(IncidentType.allCases) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    TextField("Başlık", text: $title)
                    TextEditor(text: $description).frame(height: 100)
                }
                
                Section(header: Text("Fotoğraf (Opsiyonel)")) {
                    Toggle("Fotoğraf Ekle", isOn: $attachPhoto)
                    if attachPhoto {
                        HStack {
                            Image(systemName: "photo.fill")
                                .foregroundColor(.gray)
                            Text("Simüle Edilen Fotoğraf Seçildi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Konum Seçimi")) {
                    ZStack(alignment: .center) {
                        Map(coordinateRegion: $region, showsUserLocation: true)
                            .frame(height: 250)
                            .cornerRadius(12)
                            .simultaneousGesture(
                                DragGesture().onChanged { _ in
                                    userHasMovedMap = true
                                }
                            )
                        
                        // Ortadaki Sabit Pin
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundColor(.red)
                            .padding(.bottom, 20)
                            .shadow(radius: 2)
                            .allowsHitTesting(false)
                        
                        // "Şu Anki Konumuma Git" Butonu
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    if locationManager.authorizationStatus == .notDetermined {
                                        locationManager.requestPermission()
                                    } else if let userLoc = locationManager.userLocation {
                                        withAnimation {
                                            region.center = userLoc
                                            userHasMovedMap = false
                                        }
                                    }
                                }) {
                                    Image(systemName: "location.fill")
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                                .padding()
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    
                    VStack(alignment: .center, spacing: 4) {
                        if locationManager.authorizationStatus == .denied {
                            Text("Konum İzni Reddedildi. Ayarlardan açmalısınız.")
                                .foregroundColor(.red)
                        } else if locationManager.authorizationStatus == .notDetermined {
                            Button("Konum İzni Ver") {
                                locationManager.requestPermission()
                            }
                            .foregroundColor(.blue)
                        } else if locationManager.userLocation == nil {
                            Text("Konumunuz alınıyor...")
                                .foregroundColor(.gray)
                        } else {
                            Text(userHasMovedMap ? "İşaretlenen Konum Seçilecek" : "Anlık Konumunuz Kullanılıyor")
                                .foregroundColor(userHasMovedMap ? .orange : .green)
                        }
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button(action: submitReport) {
                        Text("Bildirimi Gönder")
                            .frame(maxWidth: .infinity)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Bildirim Oluştur")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Başarılı"), message: Text("Bildiriniz şu konumda oluşturuldu: \(lastSubmittedCoords)"), dismissButton: .default(Text("Tamam")))
            }
            .onAppear {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                }
                
                if !userHasMovedMap, let userLoc = locationManager.userLocation {
                    region.center = userLoc
                }
            }
            .onReceive(locationManager.$userLocation) { newLoc in
                if !userHasMovedMap, let newLoc = newLoc {
                    withAnimation {
                        region.center = newLoc
                    }
                }
            }
        }
    }
    
    @State private var lastSubmittedCoords = ""

    private func submitReport() {
        guard let user = authManager.currentUser, !title.isEmpty else { return }
        
        let selectedLocation = region.center
        lastSubmittedCoords = String(format: "%.4f, %.4f", selectedLocation.latitude, selectedLocation.longitude)
        
        let mockImageUrl = attachPhoto ? "https://picsum.photos/seed/\(UUID().uuidString)/600/400" : nil
        
        manager.addIncident(
            type: selectedType,
            title: title,
            description: description,
            location: selectedLocation,
            user: user,
            imageUrl: mockImageUrl
        )
        
        title = ""
        description = ""
        attachPhoto = false
        userHasMovedMap = false
        showAlert = true
    }
}
