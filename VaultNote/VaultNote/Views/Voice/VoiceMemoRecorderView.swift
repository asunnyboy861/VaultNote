import AVFoundation
import SwiftUI

struct VoiceMemoRecorderView: View {
    let onSave: (String, Data, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorderWrapper()
    @State private var title = "Voice Memo"
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(recorder.isRecording ? Color.red.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 140, height: 140)

                    if recorder.isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                            .transition(.scale)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                    }
                }

                Text(formatTime(elapsedTime))
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundStyle(recorder.isRecording ? .red : .primary)

                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)

                HStack(spacing: 40) {
                    if recorder.isRecording {
                        Button {
                            stopRecording()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.red)
                                Text("Stop")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Button {
                            startRecording()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "record.circle")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.red)
                                Text("Record")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Record Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let data = recorder.recordedData {
                            onSave(title, data, elapsedTime)
                        }
                        dismiss()
                    }
                    .disabled(recorder.recordedData == nil)
                    .font(.headline)
                }
            }
        }
    }

    private func startRecording() {
        recorder.startRecording()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime = recorder.currentDuration
        }
    }

    private func stopRecording() {
        recorder.stopRecording()
        timer?.invalidate()
        timer = nil
        elapsedTime = recorder.currentDuration
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        let ms = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", m, s, ms)
    }
}

final class AudioRecorderWrapper: ObservableObject {
    @Published var isRecording = false
    @Published var recordedData: Data?
    @Published var currentDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var outputFileURL: URL?

    func startRecording() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vault_memo_\(UUID().uuidString).m4a")
        outputFileURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try AVAudioSession.sharedInstance().setCategory(.record)
            try AVAudioSession.sharedInstance().setActive(true)
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            isRecording = false
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        currentDuration = audioRecorder?.currentTime ?? 0

        if let url = outputFileURL {
            recordedData = try? Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
        }
    }
}
