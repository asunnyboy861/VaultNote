import SwiftUI

struct ShakeDestroyConfirmView: View {
    @ObservedObject var selfDestructManager: SelfDestructManager
    @Environment(\.dismiss) private var dismiss
    @State private var countdown = 5
    @State private var isDestroying = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                Text("EMERGENCY WIPE")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Shake-to-Destroy was triggered. All data will be permanently erased.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if isDestroying {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.red)
                            .scaleEffect(1.5)
                        Text("Destroying in \(countdown)...")
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(.red)
                    }
                    .onReceive(timer) { _ in
                        if countdown > 1 {
                            countdown -= 1
                        } else {
                            executeDestruction()
                        }
                    }
                }

                if !isDestroying {
                    VStack(spacing: 16) {
                        Button {
                            isDestroying = true
                        } label: {
                            Text("DESTROY ALL DATA")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: 260)
                                .padding(.vertical, 14)
                                .background(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
    }

    private func executeDestruction() {
        selfDestructManager.executeSelfDestruct()
        dismiss()
    }
}
