import SwiftUI

struct HistoryView: View {
    @ObservedObject var history: RecordingHistory

    var body: some View {
        Group {
            if history.entries.isEmpty {
                ContentUnavailableView(
                    "No Recordings",
                    systemImage: "mic.slash",
                    description: Text("Your voice notes will appear here")
                )
            } else {
                List {
                    ForEach(groupedByDate, id: \.key) { date, entries in
                        Section(header: Text(formatDate(date))) {
                            ForEach(entries) { entry in
                                NavigationLink(destination: HistoryDetailView(entry: entry)) {
                                    HistoryRow(entry: entry)
                                }
                            }
                            .onDelete { offsets in
                                deleteEntries(offsets, in: entries)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !history.entries.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        history.clearAll()
                    }
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

// MARK: - Detail View (full text + copy + share)

struct HistoryDetailView: View {
    let entry: RecordingEntry
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: entry.source == "watch" ? "applewatch" : "iphone")
                        .foregroundStyle(.secondary)
                    Text(formatDateTime(entry.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDuration(entry.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }

                // Full text
                Text(entry.text)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
        }
        .navigationTitle(formatTime(entry.date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Copy button
                    Button {
                        UIPasteboard.general.string = entry.text
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }

                    // Share button
                    ShareLink(item: entry.text) {
                        Image(systemName: "square.and.arrow.up")
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
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Text(formatTime(entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatDuration(entry.duration))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }

            Text(entry.text)
                .font(.body)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
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
