import SwiftUI

struct ReadyIndicator: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ReadyIndicator()
}
