import Combine
import UIKit

final class ScreenCaptureDetector: ObservableObject {

    @Published var isBeingCaptured = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotifications()
        checkCaptureStatus()
    }

    private func setupNotifications() {
        NotificationCenter.default
            .publisher(for: UIScreen.capturedDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkCaptureStatus()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshot()
            }
            .store(in: &cancellables)
    }

    private func checkCaptureStatus() {
        if UIScreen.main.isCaptured {
            if !isBeingCaptured {
                isBeingCaptured = true
                SecurityAuditLogger.shared.log(event: .screenRecordingDetected)
            }
        } else {
            isBeingCaptured = false
        }
    }

    private func handleScreenshot() {
        SecurityAuditLogger.shared.log(event: .screenshotDetected)
    }
}
