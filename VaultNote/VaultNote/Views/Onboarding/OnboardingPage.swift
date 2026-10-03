import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color

    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Military-Grade Encryption",
            subtitle: "Your Data, Your Control",
            description: "All notes are encrypted with AES-256-GCM before storage. Even we cannot read your data.",
            accentColor: .blue
        ),
        OnboardingPage(
            icon: "wifi.slash",
            title: "100% Offline",
            subtitle: "No Internet Required",
            description: "Your notes are always available, even without connectivity. No cloud dependency.",
            accentColor: .green
        ),
        OnboardingPage(
            icon: "eye.slash",
            title: "Zero Tracking",
            subtitle: "Privacy First",
            description: "No analytics, no ads, no data collection. Your privacy is our priority.",
            accentColor: .purple
        ),
        OnboardingPage(
            icon: "tag.fill",
            title: "One-Time Purchase",
            subtitle: "No Subscriptions",
            description: "Pay once, use forever. No hidden fees, no recurring charges.",
            accentColor: .orange
        )
    ]
}
