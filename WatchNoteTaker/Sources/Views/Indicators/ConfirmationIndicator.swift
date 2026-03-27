import SwiftUI

struct ConfirmationIndicator: View {
    var text: String?
    var filename: String?

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            Spacer()

            // Green checkmark circle
            ZStack {
                Circle()
                    .stroke(DS.success, lineWidth: 3)
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DS.success)
            }

            Text("Saved to vault")
                .font(DS.Font.heading(size: 13))
                .foregroundStyle(DS.success)

            if let filename {
                Text(filename)
                    .font(DS.Font.mono(size: 10))
                    .foregroundStyle(DS.slateLight)
            }

            if let text, !text.isEmpty {
                ScrollView {
                    Text("\"\(text.prefix(100))...\"")
                        .font(DS.Font.body(size: 10))
                        .foregroundStyle(DS.slateLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Space.sm)
                }
                .frame(maxHeight: 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ConfirmationIndicator(
        text: "I need to remember to check the API rate limits...",
        filename: "watch_2026-03-26.md"
    )
}
