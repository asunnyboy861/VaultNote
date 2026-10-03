import SwiftUI

struct TimeLockedNoteOverlay: View {
    let unlockDate: Date
    @State private var timeRemaining: String = ""

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "lock.clock")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                }

                Text("Time-Locked Note")
                    .font(.title2.bold())

                Text("This note is sealed until")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(unlockDate, style: .date)
                    .font(.headline)
                    .foregroundStyle(.blue)

                Text(timeRemaining)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text("Content will be available when the timer reaches zero.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear { updateTimeRemaining() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTimeRemaining()
        }
    }

    private func updateTimeRemaining() {
        let remaining = unlockDate.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = "Unlocked"
        } else {
            let hours = Int(remaining) / 3600
            let minutes = Int(remaining) % 3600 / 60
            let seconds = Int(remaining) % 60
            if hours > 24 {
                let days = hours / 24
                timeRemaining = "Unlocks in \(days)d \(hours % 24)h"
            } else if hours > 0 {
                timeRemaining = String(format: "%dh %02dm %02ds", hours, minutes, seconds)
            } else {
                timeRemaining = String(format: "%dm %02ds", minutes, seconds)
            }
        }
    }
}
