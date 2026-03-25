import SwiftUI

struct ProcessingIndicator: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(.orange)
            Text("Processing")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ProcessingIndicator()
}
