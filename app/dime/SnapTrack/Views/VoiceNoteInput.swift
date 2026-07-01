import SwiftUI
import Speech
import AVFoundation

struct VoiceNoteInput: View {
    let isAnalyzing: Bool
    let onLog: (String) -> Void
    let onCancel: () -> Void

    @State private var hint = ""
    @StateObject private var transcriber = SpeechTranscriber()

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                TextField("Add voice note (optional)", text: $hint)
                    .font(AppFont.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    Haptics.light()
                    transcriber.toggle { text in
                        hint = text
                    }
                } label: {
                    Image(systemName: transcriber.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(transcriber.isRecording ? .white : AppColor.primary)
                        .frame(width: 48, height: 48)
                        .background(transcriber.isRecording ? AppColor.destructive : AppColor.surfaceSecondary)
                        .clipShape(Circle())
                        .shadow(color: transcriber.isRecording ? AppColor.destructive.opacity(0.3) : .clear, radius: 8, x: 0, y: 3)
                }
                .pressable()
            }

            if transcriber.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColor.destructive)
                        .frame(width: 8, height: 8)
                    Text("Listening…")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button {
                    Haptics.medium()
                    onLog(hint)
                } label: {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Log Meal")
                                .font(AppFont.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                    .shadow(color: AppColor.primary.opacity(0.3), radius: 12, x: 0, y: 5)
                }
                .disabled(isAnalyzing)
                .pressable()

                Button {
                    Haptics.light()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(AppFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.surfaceSecondary)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                }
                .disabled(isAnalyzing)
                .pressable()
            }
        }
    }
}

@MainActor
final class SpeechTranscriber: ObservableObject {
    @Published var isRecording = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var onResult: ((String) -> Void)?

    func toggle(resultHandler: @escaping (String) -> Void) {
        if isRecording {
            stop()
        } else {
            start(resultHandler: resultHandler)
        }
    }

    private func start(resultHandler: @escaping (String) -> Void) {
        onResult = resultHandler
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized else { return }
                self?.requestMicrophoneAndBegin()
            }
        }
    }

    private func requestMicrophoneAndBegin() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                guard allowed else { return }
                self?.beginRecording()
            }
        }
    }

    private func beginRecording() {
        guard let recognizer, recognizer.isAvailable else { return }

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self, let result else { return }
            let text = result.bestTranscription.formattedString
            self.onResult?(text)
            if result.isFinal {
                self.stop()
            }
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            stop()
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {}
    }
}
