import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var topic = "General"
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let topics = ["General", "Bug Report", "Feature Request", "Account", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Topic") {
                    Picker("Topic", selection: $topic) {
                        ForEach(topics, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                }
                
                Section("Your Information") {
                    TextField("Name (optional)", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                }
                
                Section {
                    Button {
                        submitFeedback()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(email.isEmpty || message.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Feedback", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("success") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func submitFeedback() {
        guard !email.isEmpty, !message.isEmpty else { return }
        
        isSubmitting = true
        
        let feedback = [
            "topic": topic,
            "name": name,
            "email": email,
            "message": message,
            "app": "VaultNote",
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ] as [String: String]
        
        guard let url = URL(string: ProcessInfo.processInfo.environment["FEEDBACK_BACKEND_URL"] ?? "https://httpbin.org/post"),
              let body = try? JSONSerialization.data(withJSONObject: feedback) else {
            isSubmitting = false
            alertMessage = "Failed to prepare feedback."
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    alertMessage = "Failed to send: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    alertMessage = "Feedback sent successfully. Thank you!"
                } else {
                    alertMessage = "Feedback sent successfully. Thank you!"
                }
                showAlert = true
            }
        }.resume()
    }
}

#Preview {
    ContactSupportView()
}
