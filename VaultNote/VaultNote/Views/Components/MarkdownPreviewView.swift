import SwiftUI

struct MarkdownPreviewView: View {
    let text: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let attributed = try? AttributedString(
                    markdown: text,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                ) {
                    Text(attributed)
                        .font(.body)
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    Text(text)
                        .font(.body)
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }
}
