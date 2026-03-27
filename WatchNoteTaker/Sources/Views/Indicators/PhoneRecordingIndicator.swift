import SwiftUI

struct PhoneRecordingIndicator: View {
    var body: some View {
        VStack(spacing: DS.Space.sm) {
            Spacer()

            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 28))
                .foregroundStyle(DS.amber)

            Text("Recording on iPhone")
                .font(DS.Font.heading(size: 13))
                .foregroundStyle(DS.amber)

            Text("Stand by")
                .font(DS.Font.body(size: 11))
                .foregroundStyle(DS.slateLight)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    PhoneRecordingIndicator()
}
