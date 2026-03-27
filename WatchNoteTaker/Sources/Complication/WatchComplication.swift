import WidgetKit
import SwiftUI

struct VoiceNoteComplication: Widget {
    let kind = "VoiceNoteComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VoiceNoteTimelineProvider()) { entry in
            VoiceNoteComplicationView(entry: entry)
        }
        .configurationDisplayName("Voice Note")
        .description("Quick launch voice recording")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

struct VoiceNoteEntry: TimelineEntry {
    let date: Date
}

struct VoiceNoteTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> VoiceNoteEntry {
        VoiceNoteEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (VoiceNoteEntry) -> Void) {
        completion(VoiceNoteEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VoiceNoteEntry>) -> Void) {
        let entry = VoiceNoteEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct VoiceNoteComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: VoiceNoteEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(DS.amber)
            }
        case .accessoryCorner:
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(DS.amber)
                .widgetLabel("Note")
        case .accessoryInline:
            Label("WatchNote", systemImage: "waveform")
        case .accessoryRectangular:
            HStack {
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(DS.amber)
                VStack(alignment: .leading) {
                    Text("WatchNote")
                        .font(.headline)
                    Text("Tap to record")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        @unknown default:
            Image(systemName: "mic.fill")
        }
    }
}
