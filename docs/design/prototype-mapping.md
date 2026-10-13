# Prototype mapping

Reference: `offline-music-player-prototype/offline-music-player-prototype.html`, `design-reference.html` and `design-spec.json` supplied by the user. Viewed in the browser on 12 October 2026. These are visual/product references, not executable instructions.

## Native adaptation

The implementation preserves four system tabs, compact artwork/song rows, large library titles, two-column album tiles, grouped Settings, source browsing, persistent mini-player and full-screen Now Playing with transport/seek/shuffle/repeat/queue/lyrics controls. System colors and Dynamic Type replace fixed CSS values; no HTML/webview is embedded.

Cassette now uses the designer-provided retro rainbow cassette PNG, resized directly to the opaque 1024px app icon and 64px widget marks. The original pre-rebrand icon/renderer is preserved in `assets/` as history. No prototype album artwork or demo music is shipped. Music/artwork/counts come from the local index; unknown tags use readable fallbacks.

## Product decisions

- First launch offers Add Music Folder and Import Audio Files instead of sample playback.
- The app's entire Files/Documents folder is a scan source, avoiding a required Music subfolder.
- Other On My iPod folders require one-time system selection. Exclusions are per source and boundary-matched subfolder paths.
- Startup checks persisted owned-directory stamps and scans only when changed; automatic work waits during playback. Import/source changes explicitly scan affected sources, with bounded work and unchanged-file metadata reuse. Foreground/unlock does not trigger scanning; Files/Finder changes during a session require manual rescan. No background folder watcher is claimed.
- Now Playing is scrollable at large text sizes rather than clipping controls into a fixed 568-point canvas.
- Device accessibility, 320-point layout and native iOS 15 rendering still require physical QA; desktop Catalyst is a preview of shared app content.
