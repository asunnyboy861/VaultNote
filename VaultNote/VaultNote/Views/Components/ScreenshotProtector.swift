import SwiftUI

struct ScreenshotProtectionModifier: ViewModifier {

    @StateObject private var detector = ScreenCaptureDetector()
    @AppStorage("screenshotProtectionEnabled") private var isEnabled = true

    func body(content: Content) -> some View {
        ZStack {
            content

            if isEnabled && detector.isBeingCaptured {
                captureProtectionOverlay
            }
        }
    }

    private var captureProtectionOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 48))
                Text("Content Hidden")
                    .font(.headline)
                Text("Screen recording is active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: detector.isBeingCaptured)
    }
}

extension View {
    func screenshotProtected() -> some View {
        modifier(ScreenshotProtectionModifier())
    }
}
