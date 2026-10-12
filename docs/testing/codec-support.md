# Codec evidence

Backend: native **AVAudioPlayer (AVFoundation)** behind `AudioEngine`. No third-party decoder is included. Candidate extensions allow indexing; recognition is not a playback-support claim.

| Format | Current evidence | Physical iPod/iOS 15 |
| --- | --- | --- |
| WAV mono PCM 16-bit, 22.05 kHz | Generated fixture: actual native Catalyst playback, progression, pause, seek and completion checks | Pending |
| MP3 | Indexed candidate; no device fixture certified | Pending |
| AAC / M4A | Indexed candidate; no device fixture certified | Pending |
| ALAC | Indexed candidate; no device fixture certified | Pending |
| AIFF | Indexed candidate; no device fixture certified | Pending |
| FLAC | Native decoder must be evaluated per container/device | Pending |
| Ogg / Opus | No additional backend; may fail with a visible decoder error | Pending |

Metadata readers can fail even when a file is playable; filenames and Unknown Artist/Album are retained rather than dropping the track. AVAudioFile supplies a duration fallback when AVURLAsset metadata/duration loading fails. Full format-specific tags and binary synchronized lyrics still need parser work and fixtures.

The generated WAV is mathematically produced by `scripts/generate_fixture.py`; it contains no copyrighted recording and is dedicated to CC0. It lives only in the test target. The distributed app contains no audio fixtures.

Additional codecs require iOS 15/A10 measurements, licensing and binary-size review. No codec or device performance is certified from extension recognition or compilation alone.
