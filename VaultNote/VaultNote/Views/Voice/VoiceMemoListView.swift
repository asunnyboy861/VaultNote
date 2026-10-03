import AVFoundation
import CoreData
import CryptoKit
import SwiftUI

struct VoiceMemoListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = VoiceMemoListViewModel()
    @State private var isRecording = false
    @State private var recordingTitle = ""
    @State private var showRecorder = false

    var body: some View {
        List {
            if viewModel.memos.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.memos) { memo in
                    VoiceMemoRow(memo: memo, cryptoKey: viewModel.cryptoKey)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteMemo(memo)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Voice Memos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRecorder = true
                } label: {
                    Image(systemName: "mic.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showRecorder) {
            VoiceMemoRecorderView { title, data, duration in
                viewModel.saveMemo(title: title, audioData: data, duration: duration)
                showRecorder = false
            }
        }
        .onAppear {
            viewModel.fetchMemos()
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Voice Memos")
                .font(.title2.weight(.medium))
            Text("Record encrypted voice notes that only you can hear")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct VoiceMemoRow: View {
    let memo: VNVoiceMemo
    let cryptoKey: SymmetricKey
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackDelegate: PlaybackDelegate?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .onTapGesture {
                togglePlayback()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(memo.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(formatDuration(memo.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Text(memo.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else {
            guard let decryptedData = memo.decryptAudio(with: cryptoKey) else { return }
            audioPlayer = try? AVAudioPlayer(data: decryptedData)
            let delegate = PlaybackDelegate(onFinish: { isPlaying = false })
            playbackDelegate = delegate
            audioPlayer?.delegate = delegate
            audioPlayer?.play()
            isPlaying = true
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}

class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
}

final class VoiceMemoListViewModel: ObservableObject {
    @Published var memos: [VNVoiceMemo] = []
    let cryptoKey: SymmetricKey

    init() {
        let salt = VaultCrypto.getOrCreateSalt()
        cryptoKey = VaultCrypto.deriveKey(from: "default", salt: salt)
    }

    func fetchMemos() {
        let context = VaultDataController.shared.container.viewContext
        let request = VNVoiceMemo.fetchRequest() as NSFetchRequest<VNVoiceMemo>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        memos = (try? context.fetch(request)) ?? []
    }

    func saveMemo(title: String, audioData: Data, duration: Double) {
        let context = VaultDataController.shared.container.viewContext
        _ = VNVoiceMemo.create(
            in: context,
            title: title,
            audioData: audioData,
            duration: duration,
            cryptoKey: cryptoKey
        )
        SecurityAuditLogger.shared.log(event: .voiceMemoCreated)
        fetchMemos()
    }

    func deleteMemo(_ memo: VNVoiceMemo) {
        let context = VaultDataController.shared.container.viewContext
        context.delete(memo)
        try? context.save()
        fetchMemos()
    }
}
