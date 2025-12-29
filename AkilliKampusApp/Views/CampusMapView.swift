import SwiftUI
import MapKit

struct CampusMapView: View {
    @ObservedObject var manager: IncidentManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.90163, longitude: 41.24422),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    @State private var selectedIncident: Incident? = nil
    @State private var hasCenteredOnUser = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: manager.incidents) { incident in
                    MapAnnotation(coordinate: incident.coordinate) {
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedIncident = incident
                            }
                        }) {
                            VStack {
                                Image(systemName: incident.type.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .padding(8)
                                    .background(incident.type.color)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.top)
                
                // sağ alt köşedeki "Konumuma Git" butonu
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            if let userLoc = locationManager.userLocation {
                                withAnimation {
                                    region.center = userLoc
                                }
                            } else {
                                locationManager.requestPermission()
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                        .padding(.bottom, selectedIncident != nil ? 140 : 20) // detay kartı varsa yukarı kaydır
                    }
                }

                // [FIX] Kartı ZStack içine taşıyoruz ki harita üzerinde gözüksün
                if let incident = selectedIncident {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: incident.type.iconName).foregroundColor(incident.type.color)
                            Text(incident.type.rawValue).font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    selectedIncident = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                        Text(incident.title).font(.headline)
                        Text(incident.description).font(.caption).lineLimit(1).foregroundColor(.secondary)
                        
                        HStack {
                            Text(incident.lastUpdated, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("önce")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            NavigationLink(destination: IncidentDetailView(incident: incident, manager: manager, authManager: authManager)) {
                                Text("Detayı Gör")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                // Sadece izin kontrolü gerekirse burada kalabilir, 
                // ancak otomatik odaklama kaldırıldı.
            }
            .onReceive(locationManager.$userLocation) { _ in
                // Otomatik odaklama devre dışı bırakıldı.
            }
        }
        .navigationBarHidden(true)
    }
}
