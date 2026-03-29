import SwiftUI
import UniformTypeIdentifiers

struct PhoneMainView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var vaultWriter: VaultWriter
    @ObservedObject var watchService: PhoneTranscriptionService
    @ObservedObject var history: RecordingHistory
    @ObservedObject var settings: AppSettings

    @State private var showSettings = false

    var body: some View {
        PhoneRecordingView(
            viewModel: viewModel,
            vaultWriter: vaultWriter,
            watchService: watchService,
            history: history,
            showSettings: $showSettings
        )
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(settings: settings, vaultWriter: vaultWriter, history: history)
            }
        }
    }
}

// MARK: - Full-Screen Recording View

struct PhoneRecordingView: View {
    @Bindable var viewModel: RecordingViewModel
    @ObservedObject var vaultWriter: VaultWriter
    @ObservedObject var watchService: PhoneTranscriptionService
    @ObservedObject var history: RecordingHistory
    @ObservedObject var connector = WatchPhoneConnector.shared
    @Binding var showSettings: Bool

    @State private var waveAmplitudes: [CGFloat] = (0..<20).map { _ in CGFloat.random(in: 0.15...0.5) }

    private var isWatchMode: Bool {
        // Read directly from connector (Combine @Published), not ViewModel (@Observable)
        let watchRecording = watchService.isWatchRecording || (connector.remoteIsRecording && connector.remoteDevice == "watch")
        return watchRecording && viewModel.state == .idle
    }

    private var isRemoteRecording: Bool {
        connector.remoteIsRecording
    }

    private var todayNoteCount: Int {
        let calendar = Calendar.current
        return history.entries.filter { calendar.isDateInToday($0.date) }.count
    }

    var body: some View {
        ZStack {
            DS.ink.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                if isWatchMode {
                    watchRecordingContent
                } else {
                    mainContent
                }

                Spacer()

                if !isWatchMode {
                    bottomContent
                }
            }
        }
        .onAppear {
            viewModel.onRecordingSaved = { text, date, duration in
                history.add(text: text, date: date, duration: duration)
            }
            watchService.onRecordingSaved = { text, date, _ in
                history.add(text: text, date: date, duration: 0, source: "watch")
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Left: connection status (always visible)
            HStack(spacing: 4) {
                Circle()
                    .fill(connector.isConnected ? DS.success : DS.slate.opacity(0.3))
                    .frame(width: 8, height: 8)
                if connector.isConnected {
                    Text("Watch")
                        .font(DS.Font.mono(size: 11))
                        .foregroundStyle(DS.slateLight)
                }
            }

            Spacer()

            // Right: settings gear (always visible)
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(DS.slateLight)
            }
            .accessibilityIdentifier("settingsButton")
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.top, DS.Space.md)
    }

    // MARK: - Main Content (Idle / Saved / Error)

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .idle:
            idleContent
        case .recording:
            recordingContent
        case .transcribing, .saving:
            processingContent
        }
    }

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(spacing: DS.Space.md) {
            if let text = viewModel.lastTranscribedText, viewModel.errorMessage == nil {
                // Just saved state
                savedContent(text)
            } else if let error = viewModel.errorMessage {
                errorContent(error)
            } else {
                readyContent
            }
        }
    }

    private var readyContent: some View {
        VStack(spacing: DS.Space.sm) {
            Text("WatchNoteTaker")
                .font(DS.Font.display(size: 28))
                .foregroundStyle(.white)
            Text("Speak it. It's saved.")
                .font(DS.Font.body(size: 15))
                .foregroundStyle(DS.slateLight)
        }
    }

    private func savedContent(_ text: String) -> some View {
        VStack(spacing: DS.Space.md) {
            ZStack {
                Circle()
                    .stroke(DS.success, lineWidth: 3)
                    .frame(width: 60, height: 60)
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.success)
            }

            Text("Saved to vault")
                .font(DS.Font.heading(size: 17))
                .foregroundStyle(DS.success)

            ScrollView {
                Text(text)
                    .font(DS.Font.body(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DS.Space.md)
            }
            .frame(maxHeight: 200)
            .background(DS.inkMid, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .padding(.horizontal, DS.Space.lg)
        }
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(DS.amber)

            Text(message)
                .font(DS.Font.body(size: 14))
                .foregroundStyle(DS.slateLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Space.lg)
        }
    }

    // MARK: - Recording State

    private var recordingContent: some View {
        VStack(spacing: DS.Space.lg) {
            // Animated waveform
            liveWaveform
                .frame(height: 60)
                .padding(.horizontal, DS.Space.lg)

            // Live transcript
            if !viewModel.liveTranscript.isEmpty {
                ScrollView {
                    Text(viewModel.liveTranscript)
                        .font(DS.Font.body(size: 17))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal, DS.Space.lg)
            }
        }
    }

    // MARK: - Processing State

    private var processingContent: some View {
        VStack(spacing: DS.Space.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(DS.amber)

            Text(viewModel.isModelReady ? "Transcribing..." : "Loading AI model...")
                .font(DS.Font.heading(size: 17))
                .foregroundStyle(DS.amber)

            if !viewModel.liveTranscript.isEmpty {
                ScrollView {
                    Text(viewModel.liveTranscript)
                        .font(DS.Font.body(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                }
                .frame(maxHeight: 200)
                .background(DS.inkMid, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                .padding(.horizontal, DS.Space.lg)
            }
        }
    }

    // MARK: - Bottom Content

    @ViewBuilder
    private var bottomContent: some View {
        VStack(spacing: DS.Space.md) {
            if viewModel.state == .idle && viewModel.lastTranscribedText == nil && viewModel.errorMessage == nil {
                // Idle: show static waveform hint
                idleWaveform
                    .frame(height: 40)
                    .padding(.horizontal, DS.Space.xl)
            }

            // Record / Stop button
            recordButton

            // Label under button
            if viewModel.state == .recording {
                Text("Tap to stop")
                    .font(DS.Font.body(size: 13))
                    .foregroundStyle(DS.slateLight)
            } else if viewModel.state == .idle && viewModel.lastTranscribedText == nil && viewModel.errorMessage == nil {
                Text("Tap to record")
                    .font(DS.Font.body(size: 13))
                    .foregroundStyle(DS.slateLight)

                // Note counter
                if todayNoteCount > 0 {
                    Text("\(todayNoteCount) note\(todayNoteCount == 1 ? "" : "s") today")
                        .font(DS.Font.mono(size: 12))
                        .foregroundStyle(DS.slate)
                }
            }
        }
        .padding(.bottom, DS.Space.xl)
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            let wasRecording = viewModel.state == .recording
            viewModel.toggleRecording()
            if wasRecording {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } label: {
            if viewModel.state == .recording {
                // Stop button: red circle with square
                ZStack {
                    Circle()
                        .stroke(DS.recording.opacity(0.4), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.recording)
                        .frame(width: 28, height: 28)
                }
            } else {
                // Mic button: amber circle with mic icon
                ZStack {
                    Circle()
                        .stroke(DS.amber.opacity(0.4), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(DS.amber)
                        .frame(width: 68, height: 68)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DS.ink)
                }
            }
        }
        .disabled(viewModel.state == .transcribing || viewModel.state == .saving || isRemoteRecording)
    }

    // MARK: - Waveform Views

    private var idleWaveform: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(DS.slate.opacity(0.4))
                    .frame(width: 3, height: idleBarHeight(index: i))
            }
        }
    }

    private var liveWaveform: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(DS.amber)
                    .frame(width: 4, height: 60 * waveAmplitudes[i])
            }
        }
        .onAppear { animateWave() }
    }

    private func animateWave() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            waveAmplitudes = (0..<20).map { _ in CGFloat.random(in: 0.15...1.0) }
        }
    }

    private func idleBarHeight(index: Int) -> CGFloat {
        let center = 10.0
        let distance = abs(Double(index) - center)
        let maxHeight: CGFloat = 30
        let minHeight: CGFloat = 8
        return max(minHeight, maxHeight - CGFloat(distance) * 2.5)
    }

    // MARK: - Watch Mode

    private var watchRecordingContent: some View {
        VStack(spacing: DS.Space.md) {
            Image(systemName: "applewatch.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundStyle(DS.amber)

            Text("Recording on Watch")
                .font(DS.Font.heading(size: 20))
                .foregroundStyle(DS.amber)

            if watchService.isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(DS.amber)
                    Text("Transcribing...")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.slateLight)
                }
            }

            if !watchService.liveTranscript.isEmpty {
                ScrollView {
                    Text(watchService.liveTranscript)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                }
                .frame(maxHeight: 300)
                .background(DS.inkMid, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                .padding(.horizontal, DS.Space.lg)
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

/// UIKit wrapper for folder picker
struct FolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
