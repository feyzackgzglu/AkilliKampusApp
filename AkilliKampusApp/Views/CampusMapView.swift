import SwiftUI
import MapKit

struct CampusMapView: View {
    @ObservedObject var manager: IncidentManager
    
    @StateObject var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8975, longitude: 41.2311),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    @State private var selectedIncident: Incident? = nil
    
    var body: some View {
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
            .onAppear {
                // Konum izni varsa ve konum geldiyse oraya odaklan
                if let userLoc = locationManager.userLocation {
                    region.center = userLoc
                }
            }
            // ... (Pin Detay Kartı kodu aynı kalabilir veya iyileştirilebilir)
            if let incident = selectedIncident {
                // (Existing Detail Card Code)
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
                    Text(incident.description).font(.caption).lineLimit(2).foregroundColor(.secondary)
                    HStack {
                         Text(incident.dateReported, style: .time)
                         Spacer()
                         Text(incident.status.rawValue)
                             .fontWeight(.bold).foregroundColor(incident.status.color)
                    }.font(.caption)
                }
                .padding().background(Color.white).cornerRadius(15).shadow(radius: 10).padding().transition(.move(edge: .bottom))
            }
        }
    }
}
