import Foundation

#if os(watchOS)
import WatchKit

/// Keeps the watch app alive and display active during recording.
final class SessionManager: NSObject, @unchecked Sendable, WKExtendedRuntimeSessionDelegate {

    private var extendedSession: WKExtendedRuntimeSession?
    private var isActive = false

    func startKeepAlive() {
        guard !isActive else { return }

        let session = WKExtendedRuntimeSession()
        session.delegate = self
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

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Session about to expire — stop gracefully
        stopKeepAlive()
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: (any Error)?) {
        isActive = false
        extendedSession = nil
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
