import CryptoKit
import SwiftUI

struct NoteRowView: View {
    let note: VNNote
    let cryptoKey: SymmetricKey?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                if note.encryptedBody != nil {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            if let key = cryptoKey, note.encryptedBody != nil {
                let preview = note.decryptBody(with: key)
                Text(String(preview.prefix(80)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(note.tags, id: \.self) { tag in
                                TagChipView(tag: tag)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Text(note.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}
