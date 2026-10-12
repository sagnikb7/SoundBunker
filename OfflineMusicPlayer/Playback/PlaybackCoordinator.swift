import AVFoundation
import Combine
import MediaPlayer
import UIKit

@MainActor
final class PlaybackCoordinator: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var position: TimeInterval = 0
    @Published private(set) var queue: [String] = []
    @Published private(set) var queueIndex = 0
    @Published private(set) var shuffle = false
    @Published private(set) var repeatMode = RepeatMode.off
    @Published var errorMessage: String?
    var title: String? { currentTrack?.title }
    private let engine: AudioEngine
    private let preferences: UserDefaults
    private weak var library: LibraryStore?
    private var timer: Timer?
    private var notifications: [NSObjectProtocol] = []
    private var remoteTargets: [(MPRemoteCommand, Any)] = []
    private var scopedRoot: URL?
    private var shouldResume = false
    private var artwork: MPMediaItemArtwork?
    private var lastSaved = Date.distantPast

    init(engine: AudioEngine? = nil, preferences: UserDefaults = .standard) {
        self.preferences = preferences
        self.engine = engine ?? NativeAudioEngine()
        self.engine.onCompletion = { [weak self] in self?.advance(natural: true) }
        self.engine.onFailure = { [weak self] error in
            self?.pause(); self?.errorMessage = error.localizedDescription
        }
        do { try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default) }
        catch { errorMessage = error.localizedDescription }
        configureSystemControls()
    }
    deinit {
        timer?.invalidate()
        notifications.forEach(NotificationCenter.default.removeObserver)
        remoteTargets.forEach { $0.0.removeTarget($0.1) }
        scopedRoot?.stopAccessingSecurityScopedResource()
    }
    func connect(_ library: LibraryStore) {
        guard self.library == nil else { return }
        self.library = library
        if let state = try? library.database?.all("playback", as: PlaybackSnapshot.self).first,
           state.index >= 0 {
            shuffle = state.shuffle; repeatMode = state.repeatMode
            guard !state.queue.isEmpty, state.queue.indices.contains(state.index) else { return }
            queue = state.queue; queueIndex = state.index
            if let track = library.track(queue[queueIndex]) {
                currentTrack = track; duration = track.duration; position = (preferences.object(forKey: "rememberPlaybackPosition") as? Bool ?? true) ? max(0, min(state.position, duration)) : 0
            }
        }
    }
    func play(_ tracks: [Track], startingAt track: Track? = nil, shuffled: Bool = false) {
        guard !tracks.isEmpty else { return }
        queue = tracks.map(\.id); shuffle = shuffled
        if shuffled { queue.shuffle() }
        queueIndex = track.flatMap { queue.firstIndex(of: $0.id) } ?? 0
        loadCurrent(autoplay: true)
    }
    func playNext(_ track: Track) {
        if queue.isEmpty { play([track]); return }
        queue.insert(track.id, at: min(queueIndex + 1, queue.count)); persist()
    }
    func addToQueue(_ track: Track) {
        if queue.isEmpty { play([track]); return }
        queue.append(track.id); persist()
    }
    func jump(to index: Int) { guard queue.indices.contains(index) else { return }; queueIndex = index; loadCurrent(autoplay: true) }
    func toggleShuffle() {
        shuffle.toggle()
        guard queue.indices.contains(queueIndex) else { return }
        let prefix = Array(queue.prefix(queueIndex + 1))
        var tail = Array(queue.dropFirst(queueIndex + 1))
        if shuffle { tail.shuffle() }
        else { tail.sort { (library?.track($0)?.title ?? "") < (library?.track($1)?.title ?? "") } }
        queue = prefix + tail; persist()
    }
    func setRepeatMode(_ mode: RepeatMode) { repeatMode = mode; persist() }
    func cycleRepeat() { repeatMode = repeatMode == .off ? .all : repeatMode == .all ? .one : .off; persist() }
    func next() { advance(natural: false) }
    func previous() {
        if position > 3 { seek(to: 0); return }
        if queueIndex > 0 { queueIndex -= 1; loadCurrent(autoplay: true) } else { seek(to: 0) }
    }
    private func advance(natural: Bool) {
        if natural && repeatMode == .one { seek(to: 0); play(); return }
        if queueIndex + 1 < queue.count { queueIndex += 1; loadCurrent(autoplay: true) }
        else if repeatMode == .all && !queue.isEmpty { queueIndex = 0; loadCurrent(autoplay: true) }
        else { pause(); position = duration; persist(); updateNowPlaying() }
    }
    private func loadCurrent(autoplay: Bool) {
        engine.stop(); stopTimer(); releaseAccess(); isPlaying = false; position = 0
        guard let library = library else { return }
        // Skip unavailable entries with a bounded traversal. Never silently replace a track by title.
        var attempts = 0
        while attempts < queue.count, queue.indices.contains(queueIndex) {
            let id = queue[queueIndex]
            if let track = library.track(id), track.available {
                do {
                    try prepare(track)
                    currentTrack = track; duration = engine.duration; loadArtwork(track)
                    errorMessage = nil
                    if autoplay { play() } else { updateNowPlaying() }
                    persist(); return
                } catch { errorMessage = "\(track.title): \(error.localizedDescription)"; releaseAccess() }
            } else { errorMessage = "This song is unavailable. Reconnect or rescan its folder in Settings." }
            attempts += 1
            if queueIndex + 1 < queue.count { queueIndex += 1 } else { break }
        }
        currentTrack = nil; duration = 0; MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; persist()
    }
    private func prepare(_ track: Track) throws {
        guard let library = library else { throw PlaybackError.decoderFailed }
        var lastError: Error = CocoaError(.fileReadNoSuchFile)
        for location in track.locations where location.available {
            guard let source = library.sources.first(where: { $0.id == location.sourceID }),
                  source.permits(location.relativePath) else { continue }
            do {
                let root = try library.sourceURL(source)
                let accessed = root.startAccessingSecurityScopedResource()
                if accessed { scopedRoot = root }
                let file = try LocalFilePolicy.musicFile(location.relativePath, in: root)
                try engine.load(file)
                return
            } catch { lastError = error; releaseAccess() }
        }
        throw lastError
    }
    private func releaseAccess() { scopedRoot?.stopAccessingSecurityScopedResource(); scopedRoot = nil }
    func play() {
        guard let current = currentTrack, let track = library?.track(current.id), track.available else {
            if currentTrack != nil { pause(); errorMessage = "This song is unavailable or its folder is excluded." }
            return
        }
        do {
            // Restored sessions have no loaded engine and never autoplay on launch.
            if engine.duration == 0 { let resume = position; try prepare(track); engine.seek(to: resume); duration = engine.duration; loadArtwork(track) }
            try AVAudioSession.sharedInstance().setActive(true)
            if position >= duration { engine.seek(to: 0) }
            try engine.play(); isPlaying = engine.isPlaying; position = engine.currentTime
            startTimer(); updateNowPlaying()
        } catch { isPlaying = false; stopTimer(); errorMessage = error.localizedDescription; updateNowPlaying() }
    }
    func pause() {
        engine.pause(); isPlaying = false
        if engine.duration > 0 { position = engine.currentTime }
        stopTimer(); updateNowPlaying(); persist()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    func toggle() { isPlaying ? pause() : play() }
    func seek(to time: TimeInterval) {
        guard time.isFinite else { return }
        if engine.duration > 0 { engine.seek(to: time); position = engine.currentTime }
        else { position = min(max(0, time), duration) }
        updateNowPlaying(); persist()
    }
    func persist() {
        guard let db = library?.database else { return }
        do {
            try db.save(PlaybackSnapshot(queue: queue, index: queueIndex, position: position, repeatMode: repeatMode, shuffle: shuffle), key: "playback", kind: "playback")
            try db.commit(); lastSaved = Date()
        } catch { errorMessage = "Couldn't save playback state: \(error.localizedDescription)" }
    }
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.position = self.engine.currentTime
                if Date().timeIntervalSince(self.lastSaved) > 10 { self.persist() }
            }
        }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }
    private func loadArtwork(_ track: Track) {
        artwork = nil
        if let name = track.artwork, let folder = library?.artworkDirectory,
           let image = UIImage(contentsOfFile: folder.appendingPathComponent(name).path) {
            artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
    }
    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [MPMediaItemPropertyTitle: track.title, MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album, MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: position, MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0]
        if let artwork = artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    private func configureSystemControls() {
        let center = MPRemoteCommandCenter.shared()
        bind(center.playCommand) { $0.play() }; bind(center.pauseCommand) { $0.pause() }
        bind(center.togglePlayPauseCommand) { $0.toggle() }; bind(center.nextTrackCommand) { $0.next() }; bind(center.previousTrackCommand) { $0.previous() }
        remoteTargets.append((center.changePlaybackPositionCommand, center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let time = event.positionTime; Task { @MainActor [weak self] in self?.seek(to: time) }; return .success
        }))
        let nc = NotificationCenter.default
        notifications.append(nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if type == AVAudioSession.InterruptionType.began.rawValue { self.shouldResume = self.isPlaying; self.pause() }
                else if type == AVAudioSession.InterruptionType.ended.rawValue {
                    if self.shouldResume && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) { self.play() }
                    self.shouldResume = false
                }
            }
        })
        notifications.append(nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            if notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor [weak self] in self?.pause() }
            }
        })
    }
    private func bind(_ command: MPRemoteCommand, action: @escaping (PlaybackCoordinator) -> Void) {
        remoteTargets.append((command, command.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in if let self = self { action(self) } }; return .success
        }))
    }
}
