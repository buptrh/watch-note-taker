import SwiftUI

struct RecordingIndicator: View {
    var duration: TimeInterval = 0
    var liveTranscript: String = ""

    @State private var waveAmplitudes: [CGFloat] = (0..<9).map { _ in CGFloat.random(in: 0.3...1.0) }
    @State private var animating = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: REC dot + timer
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(DS.recording)
                        .frame(width: 8, height: 8)
                    Text("REC")
                        .font(DS.Font.mono(size: 10))
                        .fontWeight(.bold)
                        .foregroundStyle(DS.recording)
                }
                Spacer()
                Text(formatDuration(duration))
                    .font(DS.Font.mono(size: 10))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, DS.Space.sm)
            .padding(.top, DS.Space.xs)

            Spacer()

            // Waveform bars
            HStack(spacing: 3) {
                ForEach(0..<9, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(DS.amber)
                        .frame(width: 3, height: 12 * waveAmplitudes[i])
                }
            }
            .frame(height: 24)
            .onChange(of: animating) { _, _ in
                animateWave()
            }
            .onAppear {
                animating = true
                animateWave()
            }

            // Live transcript
            if !liveTranscript.isEmpty {
                ScrollView {
                    Text(liveTranscript)
                        .font(DS.Font.body(size: 11))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Space.sm)
                }
                .frame(maxHeight: 60)
                .padding(.top, DS.Space.sm)
            }

            Spacer()

            Text("Tap to stop")
                .font(DS.Font.body(size: 10))
                .foregroundStyle(DS.slateLight)
                .padding(.bottom, DS.Space.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }

    private func animateWave() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            waveAmplitudes = (0..<9).map { _ in CGFloat.random(in: 0.3...1.0) }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    RecordingIndicator(duration: 12, liveTranscript: "I need to remember to check the API rate limits before...")
}
