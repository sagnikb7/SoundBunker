import AVFoundation

/// Serialize blocking session activation away from UI/layout work.
actor PlaybackSession {
    static let shared = PlaybackSession()
    func activate(_ active: Bool) throws {
        try AVAudioSession.sharedInstance().setActive(active, options: active ? [] : .notifyOthersOnDeactivation)
    }
}
