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
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(buttonEnabled ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!buttonEnabled)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Skip option for vault step
            if currentStep == 2 {
                Button("Skip — I'll set up later") {
                    completeOnboarding()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
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
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("WatchNoteTaker")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Record voice notes on your Apple Watch or iPhone. Transcribed instantly and saved to your Obsidian vault.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var microphoneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: micGranted ? "mic.fill" : "mic.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(micGranted ? .green : .orange)

            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)

            if micGranted {
                Text("Microphone access granted!")
                    .font(.body)
                    .foregroundStyle(.green)
            } else {
                Text("We need microphone access to record your voice notes. Audio is processed on-device — nothing is sent to a server.")
                    .font(.body)
                    .foregroundStyle(.secondary)
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
            Image(systemName: vaultWriter.hasVaultAccess ? "folder.fill.badge.checkmark" : "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(vaultWriter.hasVaultAccess ? .green : .blue)

            Text("Obsidian Vault")
                .font(.title)
                .fontWeight(.bold)

            if vaultWriter.hasVaultAccess {
                Text("Connected to: \(vaultWriter.vaultPath)")
                    .font(.body)
                    .foregroundStyle(.green)
            } else {
                Text("Select your Obsidian vault's 00_inbox folder to save voice notes directly into your vault.")
                    .font(.body)
                    .foregroundStyle(.secondary)
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
        case 2: return vaultWriter.hasVaultAccess ? "Done" : "Select Vault Folder"
        default: return "Continue"
        }
    }

    private var buttonEnabled: Bool {
        switch currentStep {
        case 0: return true
        case 1: return true
        case 2: return true
        default: return true
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
