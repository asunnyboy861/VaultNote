import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @State private var currentPage = 0
    @State private var enableBiometricOnFinish = false

    private let pages = OnboardingPage.defaultPages

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color(.separator))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.top, 20)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(
                            page: page,
                            isLastPage: index == pages.count - 1,
                            onSkip: completeOnboarding,
                            onComplete: {
                                if index < pages.count - 1 {
                                    withAnimation { currentPage += 1 }
                                } else {
                                    completeOnboarding()
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if currentPage == pages.count - 1 {
                    securityOptionSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    var securityOptionSection: some View {
        VStack(spacing: 12) {
            Divider()

            Toggle(isOn: $enableBiometricOnFinish) {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Biometric Lock")
                            .font(.subheadline.weight(.medium))
                        Text("Require Face ID or Touch ID to open")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)

            Text("You can always change this in Settings later.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .padding(.bottom, 20)
    }

    private func completeOnboarding() {
        biometricLockEnabled = enableBiometricOnFinish
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }
}
