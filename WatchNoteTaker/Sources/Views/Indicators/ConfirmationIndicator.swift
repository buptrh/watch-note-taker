import SwiftUI

struct ConfirmationIndicator: View {
    var text: String?

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
    ConfirmationIndicator(text: "I need to remember to check the API rate limits before deploying the update.")
}
