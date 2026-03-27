import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var vaultWriter: VaultWriter
    var history: RecordingHistory? = nil
    @State private var showFolderPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.lg) {
                // HISTORY link (when accessible from settings)
                if let history {
                    settingsSection("HISTORY") {
                        NavigationLink {
                            HistoryView(history: history)
                        } label: {
                            settingsRow {
                                Text("Recording History")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(history.entries.count)")
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(DS.slateLight)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.slate)
                            }
                        }
                    }
                }

                // SAVE LOCATION section
                settingsSection("SAVE LOCATION") {
                    settingsRow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Save Folder")
                                .foregroundStyle(.white)
                            if vaultWriter.hasVaultAccess {
                                Text(vaultWriter.vaultPath)
                                    .font(DS.Font.mono(size: 13))
                                    .foregroundStyle(DS.slateLight)
                            } else {
                                Text("No folder selected")
                                    .font(DS.Font.body(size: 13))
                                    .foregroundStyle(DS.amber)
                            }
                        }
                        Spacer()
                        Image(systemName: vaultWriter.hasVaultAccess ? "chevron.right" : "folder.badge.plus")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.slate)
                    }
                    .onTapGesture { showFolderPicker = true }

                    Text("If you use Obsidian, select a folder inside your Obsidian vault.")
                        .font(DS.Font.body(size: 12))
                        .foregroundStyle(DS.slate)
                        .padding(.horizontal, DS.Space.xs)
                        .padding(.top, DS.Space.xs)
                }

                // TRANSCRIPTION section
                settingsSection("TRANSCRIPTION") {
                    settingsRow {
                        Text("Language")
                            .foregroundStyle(.white)
                        Spacer()
                        Picker("", selection: $settings.language) {
                            ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                                Text(lang.name).tag(lang.code)
                            }
                        }
                        .tint(DS.slateLight)
                    }

                    settingsRow {
                        Text("AI Model")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("large-v3-turbo")
                            .font(DS.Font.mono(size: 13))
                            .foregroundStyle(DS.slateLight)
                    }
                }

                // BEHAVIOR section
                settingsSection("BEHAVIOR") {
                    settingsRow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Action Button")
                                .foregroundStyle(.white)
                            Text("Go to Watch Settings → Action Button to assign WatchNoteTaker")
                                .font(DS.Font.body(size: 12))
                                .foregroundStyle(DS.slateLight)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.slate)
                    }
                }

                // STORAGE section
                settingsSection("STORAGE") {
                    settingsRow {
                        Text("Model: 580 MB  ·  Notes: \(notesSize)")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.slateLight)
                        Spacer()
                    }
                }

                // Remove vault access
                if vaultWriter.hasVaultAccess {
                    Button {
                        vaultWriter.removeBookmark()
                    } label: {
                        Text("Remove Save Folder")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.recording)
                    }
                    .padding(.top, DS.Space.sm)
                }
            }
            .padding(DS.Space.lg)
        }
        .background(DS.ink.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundStyle(DS.amber)
                }
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                vaultWriter.saveBookmark(for: url)
            }
        }
    }

    // MARK: - Section builder

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(DS.slate)
                .tracking(2)

            VStack(spacing: 1) {
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.md)
        .frame(maxWidth: .infinity)
        .background(DS.inkMid)
    }

    private var notesSize: String {
        // Rough estimate based on entry count
        let count = Double(max(1, 1))  // Placeholder
        return String(format: "%.1f MB", count * 2.1)
    }
}
