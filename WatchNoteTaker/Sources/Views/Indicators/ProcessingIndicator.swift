import SwiftUI

struct ProcessingIndicator: View {
    var existingText: String?
    var isModelReady: Bool = true

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            Spacer()

            // Circular progress ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(DS.amber, lineWidth: 3)
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }

            Text(isModelReady ? "Transcribing..." : "Loading AI model...")
                .font(DS.Font.heading(size: 13))
                .foregroundStyle(DS.amber)

            if let existingText, !existingText.isEmpty {
                ScrollView {
                    Text(existingText)
                        .font(DS.Font.body(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Space.sm)
                        .padding(.vertical, DS.Space.xs)
                }
                .frame(maxHeight: 60)
                .background(DS.inkMid.opacity(0.5), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .padding(.horizontal, DS.Space.xs)
                .onTapGesture { }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ProcessingIndicator(existingText: "I need to remember to check the API rate limits before deploying the update.")
}
