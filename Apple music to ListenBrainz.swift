TrackSessionManager   // logic for tracking listens
NowPlayingService     // reads Apple Music data
ScrobbleQueue         // stores + sends listens
PersistenceLayer      // local database
ListenBrainzClient    // API calls
class NowPlayingService {
    let player = MPMusicPlayerController.systemMusicPlayer

    func currentTrack() -> Track? {
        guard let item = player.nowPlayingItem else { return nil }

        return Track(
            id: item.playbackStoreID,
            title: item.title ?? "",
            artist: item.artist ?? "",
            album: item.albumTitle ?? "",
            duration: item.playbackDuration
        )
    }

    func currentTime() -> TimeInterval {
        return player.currentPlaybackTime
    }
    class TrackSessionManager {
    var current: TrackSession?
    
    func update(track: Track?, playbackTime: TimeInterval) {
        guard let track = track else { return }

        if current?.track.id != track.id {
            finalizeCurrent()
            startNew(track: track, at: playbackTime)
        } else {
            current?.updateProgress(playbackTime)
        }
    }

    func finalizeCurrent() {
        guard let session = current else { return }

        if session.shouldScrobble() {
            ScrobbleQueue.shared.add(session)
        }

        current = nil
    }
}  
struct TrackSession {
    let track: Track
    let startTime: Date
    var accumulated: TimeInterval = 0
    var lastPlaybackTime: TimeInterval = 0

    mutating func updateProgress(_ newTime: TimeInterval) {
        let delta = newTime - lastPlaybackTime
        if delta > 0 && delta < 10 {
            accumulated += delta
        }
        lastPlaybackTime = newTime
    }

    func shouldScrobble() -> Bool {
        let threshold = min(track.duration * 0.5, 240)
        return accumulated >= threshold
    }
}
    Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
    let track = nowPlaying.currentTrack()
    let time = nowPlaying.currentTime()
    sessionManager.update(track: track, playbackTime: time)
}
func applicationDidEnterBackground() {
    backgroundTask = UIApplication.shared.beginBackgroundTask()

    DispatchQueue.global().async {
        // Keep polling briefly (~30 seconds max)
        self.runShortPollingLoop()
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
    }
}
func applicationDidBecomeActive() {
    let track = nowPlaying.currentTrack()
    
    // If same track still playing:
    // assume continuous playback and fill gap
    
    sessionManager.recoverIfNeeded(currentTrack: track)
}
func submit(session: TrackSession) {
    let payload = [
        "listen_type": "single",
        "payload": [[
            "track_metadata": [
                "artist_name": session.track.artist,
                "track_name": session.track.title,
                "release_name": session.track.album
            ],
            "listened_at": Int(session.startTime.timeIntervalSince1970)
        ]]
    ]

    // POST request with token
}
}