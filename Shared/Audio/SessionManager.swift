import Foundation

#if os(watchOS)
import HealthKit

/// Keeps the watch app alive during recording using an HKWorkoutSession.
final class SessionManager: @unchecked Sendable {

    private var workoutSession: HKWorkoutSession?
    private let healthStore = HKHealthStore()
    private var isActive = false

    func startKeepAlive() {
        guard !isActive else { return }
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutSession?.startActivity(with: Date())
            isActive = true
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    func stopKeepAlive() {
        guard isActive else { return }
        workoutSession?.end()
        workoutSession = nil
        isActive = false
    }
}

#elseif os(iOS)
import UIKit
import AVFoundation

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
