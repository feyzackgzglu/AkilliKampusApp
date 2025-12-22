import SwiftUI
import MapKit

struct CampusMapView: View {
    @ObservedObject var manager: IncidentManager
    @ObservedObject var authManager: AuthManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9013, longitude: 41.2482),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var selectedIncident: Incident? = nil
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: manager.incidents) { incident in
                    MapAnnotation(coordinate: incident.coordinate) {
                        Button(action: { selectedIncident = incident }) {
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
                
                // Sağ alt köşeye "Konumuma Git" butonu ekle
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
                        .padding(.bottom, selectedIncident != nil ? 140 : 20) // Detay kartı varsa yukarı kaydır
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let userLoc = locationManager.userLocation {
                    region.center = userLoc
                }
            }
            .onReceive(locationManager.$userLocation) { newLocation in
                // Uygulama ilk açıldığında veya konum ilk geldiğinde oraya odaklan
                if let newLoc = newLocation {
                    withAnimation {
                        region.center = newLoc
                    }
                }
            }
                
                if let incident = selectedIncident {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: incident.type.iconName).foregroundColor(incident.type.color)
                            Text(incident.type.rawValue).font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            Spacer()
                            Button(action: { selectedIncident = nil }) {
                                 Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                        Text(incident.title).font(.headline)
                        Text(incident.description).font(.caption).lineLimit(1).foregroundColor(.secondary)
                        
                        HStack {
                            Text(incident.dateReported, style: .time)
                            Spacer()
                            NavigationLink(destination: IncidentDetailView(incident: incident, manager: manager, authManager: authManager)) {
                                Text("Detayı Gör")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationBarHidden(true)
        }
    }

