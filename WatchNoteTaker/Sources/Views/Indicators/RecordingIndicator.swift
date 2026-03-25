import SwiftUI

struct RecordingIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 44, height: 44)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            Text("Recording")
                .font(.caption)
                .foregroundStyle(.red)
        }
        .onAppear { isPulsing = true }
        .onDisappear { isPulsing = false }
    }
}

#Preview {
    RecordingIndicator()
}
