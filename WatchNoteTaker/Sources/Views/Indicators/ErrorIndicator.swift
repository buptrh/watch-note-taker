import SwiftUI

struct ErrorIndicator: View {
    let message: String

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DS.amber)
                Text(message)
                    .font(DS.Font.body(size: 10))
                    .foregroundStyle(DS.slateLight)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DS.Space.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ErrorIndicator(message: "Failed to save")
}
