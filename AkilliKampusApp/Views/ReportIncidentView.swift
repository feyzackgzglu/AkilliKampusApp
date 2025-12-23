import SwiftUI
import CoreLocation
import MapKit
import PhotosUI

struct ReportIncidentView: View {
    @ObservedObject var manager: IncidentManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: IncidentType = .technical
    @State private var showAlert = false
    @State private var errorAlert = false
    @State private var errorMessage = ""
    
    // [YENİ] Fotoğraf Seçimi State'leri
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isUploading = false
    
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
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(selectedImageData == nil ? "Fotoğraf Seç" : "Fotoğrafı Değiştir")
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                    
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        VStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                            
                            Button("Fotoğrafı Kaldır", role: .destructive) {
                                selectedImageData = nil
                                selectedItem = nil
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 5)
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
                        if isUploading {
                            ProgressView("Yükleniyor...")
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Bildirimi Gönder")
                                .frame(maxWidth: .infinity)
                                .bold()
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(isUploading ? Color.gray : Color.blue)
                    .disabled(isUploading || title.isEmpty)
                }
            }
            .navigationTitle("Bildirim Oluştur")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Başarılı"), message: Text("Bildiriniz şu konumda oluşturuldu: \(lastSubmittedCoords)"), dismissButton: .default(Text("Tamam")))
            }
            .alert(isPresented: $errorAlert) {
                Alert(title: Text("Hata"), message: Text(errorMessage), dismissButton: .default(Text("Tamam")))
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
        
        isUploading = true
        let selectedLocation = region.center
        lastSubmittedCoords = String(format: "%.4f, %.4f", selectedLocation.latitude, selectedLocation.longitude)
        
        if let data = selectedImageData, let uiImage = UIImage(data: data) {
            // Fotoğrafı oldukça küçültelim ki Firestore limitine takılmasın (Max 1MB)
            // 0.1 kalite ve düşük çözünürlük ile Base64'e çevirelim
            let compressedData = uiImage.jpegData(compressionQuality: 0.2)
            if let base64String = compressedData?.base64EncodedString() {
                let base64URL = "base64:\(base64String)"
                self.finalizeSubmission(user: user, location: selectedLocation, imageUrl: base64URL)
            } else {
                self.finalizeSubmission(user: user, location: selectedLocation, imageUrl: nil)
            }
        } else {
            // Fotoğraf yoksa direkt kaydet
            finalizeSubmission(user: user, location: selectedLocation, imageUrl: nil)
        }
    }
    
    private func finalizeSubmission(user: User, location: CLLocationCoordinate2D, imageUrl: String?) {
        manager.addIncident(
            type: selectedType,
            title: title,
            description: description,
            location: location,
            user: user,
            imageUrl: imageUrl
        ) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Bildirim kaydedilemedi: \(error.localizedDescription)"
                    self.isUploading = false
                    self.errorAlert = true
                } else {
                    // Başarılı
                    title = ""
                    description = ""
                    selectedImageData = nil
                    selectedItem = nil
                    userHasMovedMap = false
                    isUploading = false
                    showAlert = true
                }
            }
        }
    }
}
