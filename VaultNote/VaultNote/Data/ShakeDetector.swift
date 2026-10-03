import SwiftUI

final class ShakeDetector: ObservableObject {
    @Published var shakeTriggered = false

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "shakeToDestroyEnabled")
    }

    func onShake() {
        guard isEnabled else { return }
        shakeTriggered = true
        SecurityAuditLogger.shared.log(event: .shakeToDestroyTriggered)
    }
}

struct ShakeDetectorView<Content: View>: View {
    let content: Content
    @ObservedObject var detector: ShakeDetector

    init(detector: ShakeDetector, @ViewBuilder content: () -> Content) {
        self.detector = detector
        self.content = content()
    }

    var body: some View {
        content
            .onShake {
                detector.onShake()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeModifier(action: action))
    }
}

struct ShakeModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(ShakeRepresentable(action: action))
    }
}

struct ShakeRepresentable: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> ShakeView {
        let view = ShakeView()
        view.action = action
        return view
    }

    func updateUIView(_ uiView: ShakeView, context: Context) {
        uiView.action = action
    }
}

class ShakeView: UIView {
    var action: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            action?()
        }
    }
}
