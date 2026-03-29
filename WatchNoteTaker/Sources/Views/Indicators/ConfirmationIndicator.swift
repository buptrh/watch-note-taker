import SwiftUI

struct ConfirmationIndicator: View {
    var text: String?
    var filename: String?
    var mode: String?

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            // Green checkmark circle
            ZStack {
                Circle()
                    .stroke(DS.success, lineWidth: 3)
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.success)
            }
            .padding(.top, DS.Space.sm)

            Text("Saved")
                .font(DS.Font.heading(size: 13))
                .foregroundStyle(DS.success)

            // Show filename and mode for debugging
            if let filename {
                Text(filename)
                    .font(DS.Font.mono(size: 9))
                    .foregroundStyle(DS.slateLight)
            }
            if let mode {
                Text(mode)
                    .font(DS.Font.mono(size: 8))
                    .foregroundStyle(DS.slate)
            }

            if let text, !text.isEmpty {
                ScrollView {
                    Text(text)
                        .font(DS.Font.body(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Space.sm)
                        .padding(.vertical, DS.Space.xs)
                }
                .background(DS.inkMid.opacity(0.5), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .padding(.horizontal, DS.Space.xs)
                .onTapGesture { }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ConfirmationIndicator(
        text: "I need to remember to check the API rate limits.",
        filename: "watch_2026-03-28.md",
        mode: "local"
    )
}
