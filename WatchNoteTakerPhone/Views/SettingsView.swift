import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var vaultWriter: VaultWriter
    @State private var showFolderPicker = false

    var body: some View {
        Form {
            // Language
            Section {
                Picker("Transcription Language", selection: $settings.language) {
                    ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
            } header: {
                Text("Language")
            } footer: {
                Text("Auto Detect works for single-language recordings. For mixed Chinese/English, select Chinese — it handles English words better than the reverse.")
            }

            // Vault
            Section {
                if vaultWriter.hasVaultAccess {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.green)
                        Text(vaultWriter.vaultPath)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }

                    Button("Change Vault Folder") {
                        showFolderPicker = true
                    }

                    Button("Remove Vault Access", role: .destructive) {
                        vaultWriter.removeBookmark()
                    }
                } else {
                    HStack {
                        Image(systemName: "folder.badge.questionmark")
                            .foregroundStyle(.orange)
                        Text("Not connected")
                            .foregroundStyle(.secondary)
                    }

                    Button("Select Obsidian Vault Folder") {
                        showFolderPicker = true
                    }
                }
            } header: {
                Text("Obsidian Vault")
            } footer: {
                Text("Select your vault's 00_inbox folder. Notes save directly there — no sync needed.")
            }

            // Info
            Section {
                HStack {
                    Text("Watch Model")
                    Spacer()
                    Text("whisper-base (140MB)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Phone Model")
                    Spacer()
                    Text("large-v3-turbo (547MB)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                vaultWriter.saveBookmark(for: url)
            }
        }
    }
}
