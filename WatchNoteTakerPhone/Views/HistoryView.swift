import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: RecordingHistory

    var body: some View {
        Group {
            if history.entries.isEmpty {
                VStack(spacing: DS.Space.md) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(DS.slate)
                    Text("No Recordings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Your voice notes will appear here")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.slateLight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.ink.ignoresSafeArea())
            } else {
                List {
                    ForEach(groupedByDate, id: \.key) { date, entries in
                        Section(header: Text(formatDate(date)).foregroundStyle(DS.slateLight)) {
                            ForEach(entries) { entry in
                                NavigationLink(destination: HistoryDetailView(entry: entry)) {
                                    HistoryRow(entry: entry)
                                }
                                .listRowBackground(DS.inkMid)
                            }
                            .onDelete { offsets in
                                deleteEntries(offsets, in: entries)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(DS.ink.ignoresSafeArea())
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if !history.entries.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        history.clearAll()
                    }
                    .foregroundStyle(DS.recording)
                }
            }
        }
    }

    private var groupedByDate: [(key: String, value: [RecordingEntry])] {
        let grouped = Dictionary(grouping: history.entries) { entry in
            formatDate(entry.date)
        }
        return grouped.sorted { $0.value.first!.date > $1.value.first!.date }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatDate(_ string: String) -> String { string }

    private func deleteEntries(_ offsets: IndexSet, in sectionEntries: [RecordingEntry]) {
        for offset in offsets {
            let entry = sectionEntries[offset]
            if let index = history.entries.firstIndex(where: { $0.id == entry.id }) {
                history.entries.remove(at: index)
            }
        }
    }
}

// MARK: - Detail View

struct HistoryDetailView: View {
    let entry: RecordingEntry
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                // Header
                HStack {
                    Image(systemName: entry.source == "watch" ? "applewatch" : "iphone")
                        .foregroundStyle(DS.slateLight)
                    Text(formatDateTime(entry.date))
                        .font(.subheadline)
                        .foregroundStyle(DS.slateLight)
                    Spacer()
                    Text(formatDuration(entry.duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(DS.slateLight)
                        .padding(.horizontal, DS.Space.sm)
                        .padding(.vertical, DS.Space.xs)
                        .background(DS.inkMid, in: Capsule())
                }

                // Full text
                Text(entry.text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
            }
            .padding(DS.Space.lg)
        }
        .background(DS.ink.ignoresSafeArea())
        .navigationTitle(formatTime(entry.date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DS.Space.md) {
                    Button {
                        UIPasteboard.general.string = entry.text
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(DS.amber)
                    }

                    ShareLink(item: entry.text) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(DS.amber)
                    }
                }
            }
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
}

// MARK: - Row View

struct HistoryRow: View {
    let entry: RecordingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.source == "watch" ? "applewatch" : "iphone")
                    .foregroundStyle(DS.slateLight)
                    .font(.caption)

                Text(formatTime(entry.date))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(DS.slateLight)

                Spacer()

                Text(formatDuration(entry.duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DS.slate)
                    .padding(.horizontal, DS.Space.sm)
                    .padding(.vertical, DS.Space.xs)
                    .background(DS.ink, in: Capsule())
            }

            Text(entry.text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(3)
        }
        .padding(.vertical, DS.Space.xs)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
}
