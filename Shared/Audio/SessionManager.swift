import Foundation

#if os(watchOS)
import WatchKit

/// Keeps the watch app alive during recording.
/// Uses extended runtime session (no HealthKit entitlement needed).
final class SessionManager: @unchecked Sendable {

    private var extendedSession: WKExtendedRuntimeSession?
    private var isActive = false

    func startKeepAlive() {
        guard !isActive else { return }

        let session = WKExtendedRuntimeSession()
        session.start()
        extendedSession = session
        isActive = true
    }

    func stopKeepAlive() {
        guard isActive else { return }
        extendedSession?.invalidate()
        extendedSession = nil
        isActive = false
    }
}

#elseif os(iOS)
import UIKit

/// Keeps the iPhone app alive during recording/transcription.
final class SessionManager: @unchecked Sendable {

    private var isActive = false

    @MainActor
    func startKeepAlive() {
        guard !isActive else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        isActive = true
    }

    @MainActor
    func stopKeepAlive() {
        guard isActive else { return }
        UIApplication.shared.isIdleTimerDisabled = false
        isActive = false
    }
}

#endif
