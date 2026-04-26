import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var authManager: VaultAuthManager
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)
                
                Text("VaultNote")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your Mind, Your Device")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    Task {
                        isAuthenticating = true
                        _ = await authManager.authenticate()
                        isAuthenticating = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: authManager.biometricIcon)
                        }
                        Text(isAuthenticating ? "Authenticating..." : "Unlock")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isAuthenticating)
                
                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

#Preview {
    LockScreenView()
        .environmentObject(VaultAuthManager())
}
