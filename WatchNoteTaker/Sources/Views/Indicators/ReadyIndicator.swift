import SwiftUI

struct ReadyIndicator: View {
    var body: some View {
        VStack(spacing: DS.Space.sm) {
            Text("WatchNote")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            // Waveform icon
            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(DS.slateLight)

            VStack(spacing: DS.Space.xs) {
                Text("Press Action Button")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.slateLight)
                Text("to record")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.slateLight)
            }
            .padding(.top, DS.Space.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.ink)
    }
}

#Preview {
    ReadyIndicator()
}
