import SwiftUI

struct ConfirmationIndicator: View {
    var text: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                Text("Saved")
                    .font(.caption)
                    .foregroundStyle(.green)
                if let text, !text.isEmpty {
                    Text(text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 16)
        }
    }
}

#Preview {
    ConfirmationIndicator(text: "Remember to review the design docs")
}
