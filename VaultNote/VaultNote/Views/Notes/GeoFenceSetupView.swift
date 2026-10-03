import CoreLocation
import MapKit
import SwiftUI

struct GeoFenceSetupView: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var radius: Double
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedRadius: GeoFenceRadius = .hundredMeters
    @State private var pinCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $position) {
                    Marker("Note Location", coordinate: pinCoordinate)
                    MapCircle(center: pinCoordinate, radius: selectedRadius.meters)
                        .foregroundStyle(.blue.opacity(0.15))
                        .stroke(.blue, lineWidth: 2)
                }
                .frame(height: 300)
                .mapStyle(.standard)
                .onAppear {
                    if latitude != 0 || longitude != 0 {
                        pinCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    } else if let location = LocationManager.shared.currentLocation {
                        pinCoordinate = location.coordinate
                    }
                    position = .region(
                        MKCoordinateRegion(
                            center: pinCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }

                Form {
                    Section("Radius") {
                        Picker("Fence Radius", selection: $selectedRadius) {
                            ForEach(GeoFenceRadius.allCases) { r in
                                Text(r.displayName).tag(r)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Coordinates") {
                        LabeledContent("Latitude") {
                            Text(String(format: "%.4f", pinCoordinate.latitude))
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("Longitude") {
                            Text(String(format: "%.4f", pinCoordinate.longitude))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("How Geo-Fence Works", systemImage: "info.circle")
                                .font(.subheadline.weight(.medium))
                            Text("This note will only be visible when you are within the designated area. Leave the area and it locks automatically.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Geo-Fence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Set Fence") {
                        latitude = pinCoordinate.latitude
                        longitude = pinCoordinate.longitude
                        radius = selectedRadius.meters
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
}

enum GeoFenceRadius: Double, CaseIterable, Identifiable {
    case fiftyMeters = 50
    case hundredMeters = 100
    case fiveHundredMeters = 500
    case oneKilometer = 1000

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .fiftyMeters: return "50m"
        case .hundredMeters: return "100m"
        case .fiveHundredMeters: return "500m"
        case .oneKilometer: return "1km"
        }
    }

    var meters: Double { rawValue }
}
