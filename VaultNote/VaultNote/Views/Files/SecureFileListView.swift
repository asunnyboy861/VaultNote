import CryptoKit
import CoreData
import PhotosUI
import SwiftUI

struct SecureFileListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SecureFileListViewModel()
    @State private var showingImporter = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingDocumentPicker = false

    var body: some View {
        List {
            if viewModel.files.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.files) { file in
                    SecureFileRow(file: file, cryptoKey: viewModel.cryptoKey)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteFile(file)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Secure Files")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Import Photo", systemImage: "photo")
                    }

                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label("Import Document", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.importFile(name: "Photo", fileType: "image", data: data)
                    selectedPhotoItem = nil
                }
            }
        }
        .fileImporter(isPresented: $showingDocumentPicker, allowedContentTypes: [.pdf, .text, .plainText]) { result in
            switch result {
            case .success(let url):
                if let data = try? Data(contentsOf: url) {
                    let name = url.lastPathComponent
                    let ext = url.pathExtension.lowercased()
                    viewModel.importFile(name: name, fileType: ext.isEmpty ? "document" : ext, data: data)
                }
            case .failure:
                break
            }
        }
        .onAppear {
            viewModel.fetchFiles()
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.lock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Secure Files")
                .font(.title2.weight(.medium))
            Text("Import and encrypt photos, PDFs, and documents")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct SecureFileRow: View {
    let file: VNSecureFile
    let cryptoKey: SymmetricKey
    @State private var thumbnailImage: Image?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(fileTypeColor.opacity(0.15))
                    .frame(width: 42, height: 42)

                if let img = thumbnailImage {
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: fileTypeIcon)
                        .font(.body)
                        .foregroundStyle(fileTypeColor)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(file.name ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(file.fileType?.uppercased() ?? "FILE")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(ByteCountFormatter.string(fromByteCount: file.fileSize, countStyle: .file))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            loadThumbnail()
        }
    }

    private var fileTypeIcon: String {
        switch file.fileType {
        case "image", "jpg", "jpeg", "png", "heic": return "photo"
        case "pdf": return "doc.richtext"
        case "text", "txt", "md": return "doc.text"
        default: return "doc"
        }
    }

    private var fileTypeColor: Color {
        switch file.fileType {
        case "image", "jpg", "jpeg", "png", "heic": return .green
        case "pdf": return .red
        default: return .blue
        }
    }

    private func loadThumbnail() {
        guard let data = file.decryptThumbnail(with: cryptoKey) ?? file.decryptData(with: cryptoKey),
              file.fileType == "image" || file.fileType == "jpg" || file.fileType == "jpeg" || file.fileType == "png" else { return }
        if let uiImage = UIImage(data: data) {
            thumbnailImage = Image(uiImage: uiImage)
        }
    }
}

final class SecureFileListViewModel: ObservableObject {
    @Published var files: [VNSecureFile] = []
    let cryptoKey: SymmetricKey

    init() {
        let salt = VaultCrypto.getOrCreateSalt()
        cryptoKey = VaultCrypto.deriveKey(from: "default", salt: salt)
    }

    func fetchFiles() {
        let context = VaultDataController.shared.container.viewContext
        let request = VNSecureFile.fetchRequest() as NSFetchRequest<VNSecureFile>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        files = (try? context.fetch(request)) ?? []
    }

    func importFile(name: String, fileType: String, data: Data) {
        let context = VaultDataController.shared.container.viewContext
        var thumbnail: Data?
        if fileType == "image" || fileType == "jpg" || fileType == "jpeg" || fileType == "png" {
            if let image = UIImage(data: data) {
                thumbnail = image.jpegData(compressionQuality: 0.3)
            }
        }
        _ = VNSecureFile.create(
            in: context,
            name: name,
            fileType: fileType,
            data: data,
            thumbnail: thumbnail,
            cryptoKey: cryptoKey
        )
        SecurityAuditLogger.shared.log(event: .secureFileImported, details: name)
        fetchFiles()
    }

    func deleteFile(_ file: VNSecureFile) {
        let context = VaultDataController.shared.container.viewContext
        context.delete(file)
        try? context.save()
        fetchFiles()
    }
}
