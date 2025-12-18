import SwiftUI
import CoreLocation
import MapKit

struct ReportIncidentView: View {
    @ObservedObject var manager: IncidentManager
    @ObservedObject var authManager: AuthManager
    
    // Konum Yöneticisi
    @StateObject var locationManager = LocationManager()
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: IncidentType = .technical
    @State private var showAlert = false
    
    // Harita Bölgesi (Varsayılan: Kampüs Merkezi)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
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
                
                Section(header: Text("Konum Seçimi")) {
                    ZStack(alignment: .center) {
                        Map(coordinateRegion: $region, showsUserLocation: true)
                            .frame(height: 250)
                            .cornerRadius(12)
                            .gesture(
                                DragGesture().onChanged { _ in
                                    userHasMovedMap = true
                                }
                            )
                        
                        // Ortadaki Sabit Pin
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundColor(.red)
                            .padding(.bottom, 20) // Pinin ucu merkeze gelsin diye
                            .shadow(radius: 2)
                        
                        // "Şu Anki Konumuma Git" Butonu
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    if let userLoc = locationManager.userLocation {
                                        withAnimation {
                                            region.center = userLoc
                                            userHasMovedMap = false // Tekrar oto konuma döndü
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
                    .listRowInsets(EdgeInsets()) // Kenar boşluklarını kaldır
                    
                    Text(userHasMovedMap ? "İşaretlenen Konum Seçilecek" : "Anlık Konumunuz Kullanılıyor")
                        .font(.caption)
                        .foregroundColor(userHasMovedMap ? .orange : .green)
                        .frame(maxWidth: .infinity, alignment: .center)
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
                Alert(title: Text("Başarılı"), message: Text("Bildiriniz işaretlediğiniz konumda oluşturuldu."), dismissButton: .default(Text("Tamam")))
            }
            .onAppear {
                // İlk açılışta konum izni varsa oraya odaklan (eğer kullanıcı henüz manual hareket ettirmediyse)
                if !userHasMovedMap, let userLoc = locationManager.userLocation {
                    region.center = userLoc
                }
            }
            // Konum güncellenince haritayı oraya taşı (sadece ilk başta)
            .onReceive(locationManager.$userLocation) { newLoc in
                if !userHasMovedMap, let newLoc = newLoc {
                    withAnimation {
                        region.center = newLoc
                    }
                }
            }
        }
    }
    
    private func submitReport() {
        guard let user = authManager.currentUser, !title.isEmpty else { return }
        
        // Seçilen konum haritanın tam merkezi
        let selectedLocation = region.center
        
        manager.addIncident(type: selectedType, title: title, description: description, location: selectedLocation, user: user)
        
        // Reset steps
        title = ""
        description = ""
        showAlert = true
    }
}
