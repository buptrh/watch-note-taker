import SwiftUI

struct ReadyIndicator: View {
    var body: some View {
        VStack(spacing: DS.Space.sm) {
            Text("WatchNote")
                .font(DS.Font.display(size: 20))
                .foregroundStyle(.white)

            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(DS.slateLight)

            Text("Tap to record")
                .font(DS.Font.body(size: 12))
                .foregroundStyle(DS.slateLight)
                .padding(.top, DS.Space.xs)

            // Amber ready dot
            Circle()
                .fill(DS.amber)
                .frame(width: 6, height: 6)
                .padding(.top, DS.Space.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ReadyIndicator()
}
