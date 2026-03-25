import SwiftUI

struct ConfirmationIndicator: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Saved")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    ConfirmationIndicator()
}
