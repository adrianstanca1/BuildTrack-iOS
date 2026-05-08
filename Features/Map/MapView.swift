import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Query(filter: #Predicate<Project> { $0.latitude != nil && $0.longitude != nil })
    private var mappableProjects: [Project]
    
    @State private var camera: MapCameraPosition = .automatic
    @State private var selectedProject: Project?
    @State private var showSheet = false
    
    var body: some View {
        Map(position: $camera, selection: $selectedProject) {
            ForEach(mappableProjects) { project in
                if let lat = project.latitude, let lon = project.longitude {
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    Marker(project.name, systemImage: project.status.icon, coordinate: coord)
                        .tint(BuildTrackColors.statusColor(project.status))
                        .tag(project)
                    
                    Annotation(project.name, coordinate: coord) {
                        ProjectAnnotationView(project: project)
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            if let first = mappableProjects.first,
               let lat = first.latitude, let lon = first.longitude {
                let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                camera = .region(region)
            }
        }
        .onChange(of: selectedProject) { _, project in
            if project != nil { showSheet = true }
        }
        .sheet(isPresented: $showSheet) {
            if let project = selectedProject {
                NavigationStack {
                    ProjectDetailView(project: project)
                        .toolbar { Button("Done") { showSheet = false } }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if mappableProjects.isEmpty {
                MapEmptyOverlay()
            }
        }
    }
}

struct ProjectAnnotationView: View {
    let project: Project
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: project.status.icon)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(8)
                .background(BuildTrackColors.statusColor(project.status))
                .clipShape(Circle())
            
            Text(project.name)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

struct MapEmptyOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.title2)
            Text("No project locations")
                .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

#Preview {
    MapView()
        .modelContainer(for: [Project.self])
}
