import SwiftUI

struct ReadyIndicator: View {
    var isConnected: Bool = false

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            Text("WatchNote")
                .font(DS.Font.display(size: 20))
                .foregroundStyle(.white)

            // Waveform icon
            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(DS.slateLight)

            Text("Tap to record")
                .font(DS.Font.body(size: 12))
                .foregroundStyle(DS.slateLight)
                .padding(.top, DS.Space.xs)

            // Connection indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(isConnected ? DS.success : DS.slate)
                    .frame(width: 6, height: 6)
                if isConnected {
                    Text("iPhone")
                        .font(DS.Font.mono(size: 9))
                        .foregroundStyle(DS.slateLight)
                }
            }
            .padding(.top, DS.Space.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ReadyIndicator(isConnected: true)
}
