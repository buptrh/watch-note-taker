# WatchNoteTaker — Production Gap Analysis

> Comprehensive audit of what's needed to ship this app. Organized by severity.
> Assessed: 2026-03-27

---

## P0 — CRITICAL (Blocks App Store / Causes Crashes)

### NSMicrophoneUsageDescription
- **Risk**: App crashes on first mic access if key is missing from final binary
- **Status**: Set via `INFOPLIST_KEY_` in project.yml settings, but custom `info: path:` block may override
- **Action**: Verify key exists in built .app Info.plist for both targets
- **Files**: `project.yml`, `WatchNoteTaker/Info.plist`, `WatchNoteTakerPhone/Info.plist`

### Privacy Manifest (PrivacyInfo.xcprivacy)
- **Risk**: Apple requires this for apps using AVFoundation, UserDefaults, file access
- **Action**: Create `PrivacyInfo.xcprivacy` declaring API usage categories
- **Categories needed**: File timestamp access, UserDefaults, microphone, disk space

### App Icons
- **Risk**: Submission impossible without icons
- **Action**: Need design assets for the soundwave→pen stroke mark from design system
- **Sizes**: 1024x1024 (store), plus watchOS and iOS icon sets

### Voice Data Stored in Plaintext
- **Risk**: Full transcription text stored unencrypted in UserDefaults
- **Action**: Move `RecordingHistory` to file storage with `NSFileProtectionComplete`
- **Files**: `WatchNoteTakerPhone/Services/RecordingHistory.swift`

---

## P1 — HIGH (Production Stability / Data Loss)

### Concurrency: Audio Callbacks Not MainActor-Bound
- `AudioRecorder.onChunkReady` fires on audio engine thread
- Accesses `@MainActor`-isolated `RecordingViewModel` properties → data race
- **Fix**: Wrap callback dispatch in `Task { @MainActor in ... }`
- **Files**: `AudioRecorder.swift:39-51`, `RecordingViewModel.swift:94-99`

### WatchConnectivity: No Delivery Guarantee
- `sendMessage` uses `replyHandler: nil` — can't confirm delivery
- If "recordingComplete" message fails, `PhoneTranscriptionService` hangs forever
- File transfer retries read from URLs that watchOS may have cleaned up
- **Fix**: Add replyHandler, add timeout to PhoneTranscriptionService finalization
- **Files**: `WatchPhoneConnector.swift:53`, `PhoneTranscriptionService.swift:32-44`

### File Write Race Condition
- `NoteStore` and `VaultWriter` do check-then-write (`fileExists` → read → append → write`)
- Two recordings finishing simultaneously can corrupt the daily log file
- **Fix**: Write to temp file, then atomic rename; or use file coordination
- **Files**: `NoteStore.swift:23-28`, `VaultWriter.swift:23-45`

### WhisperKit Model Never Unloaded
- ~140 MB on watch, ~547 MB on phone, cached forever once loaded
- Watch has ~1 GB RAM — model uses 14%
- **Fix**: Add `didReceiveMemoryWarning` handler; unload after idle timeout
- **Files**: `TranscriptionEngine.swift:51-70`

### No Interruption Handling
- Phone call/Siri during recording: audio engine keeps running, no pause/resume
- App backgrounding during recording: no graceful save of partial content
- WKExtendedRuntimeSession has no delegate, no 10-minute limit monitoring
- **Fix**: Observe `AVAudioSession.interruptionNotification`, handle scene phase changes
- **Files**: `RecordingViewModel.swift`, `SessionManager.swift`

### Silent Save Failures
- If `noteStore.save()` throws, recording is lost with no error shown
- `PhoneTranscriptionService` silently drops failed saves with `print()`
- **Fix**: Surface save errors to UI; implement retry queue
- **Files**: `RecordingViewModel.swift:176`, `PhoneTranscriptionService.swift:105-116`

---

## P2 — MEDIUM (User Experience / Quality)

### Zero Accessibility
- No VoiceOver labels on any interactive element (tap gestures, buttons, states)
- Fixed font sizes — no Dynamic Type support
- Waveform animations ignore `accessibilityReduceMotion`
- **Fix**: Add `.accessibilityLabel()`, `.accessibilityHint()`, check reduced motion
- **Files**: All view files

### No Structured Logging
- 30+ `print()` statements across the codebase
- No `os.Logger`, no crash reporting, no way to debug production issues
- **Fix**: Replace with unified `os.Logger` per subsystem
- **Files**: All files with `print()`

### Phone-Side Tests Missing
- Only watch unit tests exist (29 tests)
- No tests for: `PhoneTranscriptionService`, `VaultWriter`, `RecordingHistory`, `AppSettings`
- No integration tests for WatchConnectivity
- **Fix**: Add test targets for phone services and view models

### VADChunker Buffers Unbounded
- `accumulatedBuffers` grows without limit during recording
- Very long recording could exhaust memory
- **Fix**: Add max buffer count or memory limit; flush periodically
- **Files**: `VADChunker.swift:15`

### Audio Permission Not Checked Before Recording
- `AudioRecorder.start()` sets audio session category without checking permission first
- Will fail with generic error if mic not granted
- **Fix**: Check `AVAudioApplication.shared.recordPermission` before starting
- **Files**: `AudioRecorder.swift:16-24`

---

## P3 — LOW (Polish / Pre-Launch)

### No Version/Build Increment System
- Hardcoded `1.0` in settings view
- Need automated versioning for releases

### No README, LICENSE, CHANGELOG
- No documentation for contributors or open-source compliance

### No Privacy Policy Document
- Required for App Store if accessing microphone, file system, device-to-device transfer

### Temp Audio Files Not Cleaned on Launch
- `AudioConverter` uses `defer` to remove temp files
- Crash between write and cleanup leaves orphaned files
- **Fix**: Clean temp directory on app launch

### Mono-Channel Assumption
- All audio processing (VAD, RMS, normalization) assumes channel 0
- Stereo input silently drops second channel
- **Files**: `AudioRecorder.swift`, `VADChunker.swift`, `TranscriptionEngine.swift`

### Callback Layering on Repeated Recordings
- `PhoneTranscriptionService.onAudioChunkReceived` closure set once but never cleared
- Multiple recording cycles could layer callbacks
- **Files**: `PhoneTranscriptionService.swift:26-30`

---

## Effort Estimates

| Priority | Item | Effort |
|----------|------|--------|
| P0 | Verify mic permission in binary | 5 min |
| P0 | Add PrivacyInfo.xcprivacy | 30 min |
| P0 | App icons | Needs designer |
| P0 | Encrypt RecordingHistory | 1 hr |
| P1 | Fix MainActor audio callbacks | 2 hrs |
| P1 | WatchConnectivity replyHandler + timeout | 3 hrs |
| P1 | Atomic file writes | 1 hr |
| P1 | WhisperKit memory pressure handling | 2 hrs |
| P1 | Interruption handling | 2 hrs |
| P1 | Error UI for save failures | 1 hr |
| P2 | Accessibility labels + reduced motion | 2 hrs |
| P2 | Replace print() with os.Logger | 1 hr |
| P2 | Phone-side tests | 4 hrs |
| P2 | VAD buffer limits | 30 min |
| P3 | Privacy policy, README, versioning | 2 hrs |
| P3 | Temp file cleanup | 30 min |

**Total estimated: ~23 hours of engineering work**
