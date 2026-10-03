import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let onSkip: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(page.accentColor)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.headline)
                    .foregroundStyle(page.accentColor)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    onComplete()
                } label: {
                    Text(isLastPage ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(page.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !isLastPage {
                    Button("Skip") {
                        onSkip()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }
}
