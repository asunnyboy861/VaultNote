import CoreLocation
import SwiftUI

struct GeoFenceStatusView: View {
    let latitude: Double
    let longitude: Double
    let radius: Double
    @StateObject private var locationManager = LocationManager.shared

    var isWithinFence: Bool {
        locationManager.isWithinFence(latitude: latitude, longitude: longitude, radius: radius)
    }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "location.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
            }

            Text("Geo-Fenced Note")
                .font(.title2.bold())

            Text("This note is locked to a specific location")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Current Distance")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(distanceString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }
            .padding(.vertical, 8)

            Text("Move to the designated location to unlock this note.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var distanceString: String {
        guard let location = locationManager.currentLocation else { return "Unknown" }
        let fenceCenter = CLLocation(latitude: latitude, longitude: longitude)
        let distance = location.distance(from: fenceCenter)
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
}
