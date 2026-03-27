import SwiftUI

struct ProcessingIndicator: View {
    var existingText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                ProgressView()
                    .tint(.orange)
                Text("Transcribing...")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let existingText, !existingText.isEmpty {
                    Text(existingText)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    ProcessingIndicator(existingText: "Some text already transcribed")
}
