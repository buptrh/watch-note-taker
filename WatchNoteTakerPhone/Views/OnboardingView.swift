import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct OnboardingView: View {
    @ObservedObject var vaultWriter: VaultWriter
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var micGranted = false
    @State private var showFolderPicker = false

    var body: some View {
        ZStack {
            DS.ink.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: DS.Space.sm) {
                    ForEach(0..<3) { step in
                        Circle()
                            .fill(step <= currentStep ? DS.amber : DS.slate.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Step content
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    microphoneStep
                case 2:
                    vaultStep
                default:
                    EmptyView()
                }

                Spacer()

                // Bottom button
                Button {
                    handleNext()
                } label: {
                    Text(buttonLabel)
                        .font(.headline)
                        .foregroundStyle(DS.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DS.amber, in: RoundedRectangle(cornerRadius: DS.Radius.xl))
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.bottom, DS.Space.md)

                // Skip option for vault step
                if currentStep == 2 {
                    Button("Skip — I'll set up later") {
                        completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundStyle(DS.slateLight)
                    .padding(.bottom, DS.Space.lg)
                }
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                vaultWriter.saveBookmark(for: url)
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(DS.amber.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(DS.amber)
                    .frame(width: 84, height: 84)
                Image(systemName: "mic.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.ink)
            }

            Text("WatchNoteTaker")
                .font(DS.Font.display(size: 28))
                .foregroundStyle(.white)

            Text("Record voice notes on your Apple Watch or iPhone. Transcribed instantly and saved to your Obsidian vault.")
                .font(.system(size: 15))
                .foregroundStyle(DS.slateLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var microphoneStep: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(micGranted ? DS.success.opacity(0.15) : DS.amber.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: micGranted ? "mic.fill" : "mic.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(micGranted ? DS.success : DS.amber)
            }

            Text("Microphone Access")
                .font(DS.Font.heading(size: 24))
                .foregroundStyle(.white)

            if micGranted {
                Text("Microphone access granted!")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.success)
            } else {
                Text("We need microphone access to record your voice notes. Audio is processed on-device — nothing is sent to a server.")
                    .font(DS.Font.body(size: 15))
                    .foregroundStyle(DS.slateLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .onAppear {
            checkMicPermission()
        }
    }

    private var vaultStep: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(vaultWriter.hasVaultAccess ? DS.success.opacity(0.15) : DS.amber.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: vaultWriter.hasVaultAccess ? "folder.fill.badge.checkmark" : "folder.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(vaultWriter.hasVaultAccess ? DS.success : DS.amber)
            }

            Text("Save Location")
                .font(DS.Font.heading(size: 24))
                .foregroundStyle(.white)

            if vaultWriter.hasVaultAccess {
                Text("Saving to: \(vaultWriter.vaultPath)")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.success)
            } else {
                Text("Pick a folder to save your voice notes. If you use Obsidian, select a folder in your vault and notes will appear there automatically.")
                    .font(DS.Font.body(size: 15))
                    .foregroundStyle(DS.slateLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Logic

    private var buttonLabel: String {
        switch currentStep {
        case 0: return "Get Started"
        case 1: return micGranted ? "Continue" : "Grant Microphone Access"
        case 2: return vaultWriter.hasVaultAccess ? "Done" : "Select Folder"
        default: return "Continue"
        }
    }

    private func handleNext() {
        switch currentStep {
        case 0:
            withAnimation { currentStep = 1 }
        case 1:
            if micGranted {
                withAnimation { currentStep = 2 }
            } else {
                requestMicPermission()
            }
        case 2:
            if vaultWriter.hasVaultAccess {
                completeOnboarding()
            } else {
                showFolderPicker = true
            }
        default:
            break
        }
    }

    private func checkMicPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            micGranted = true
        default:
            micGranted = false
        }
    }

    private func requestMicPermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                micGranted = granted
                if granted {
                    withAnimation { currentStep = 2 }
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        onComplete()
    }
}
