# Metadata, playlists and access

## Selected folders

The system picker grants a selected directory; minimal bookmarks persist that grant and security-scope access is balanced around scans/playback. Local/provider folders are no longer refused just because their path contains File Provider Storage. Download provider music in Files first. Cloud-only iCloud audio, symbolic links and playback paths escaping the source root remain rejected. This does not provide global access to On My iPod.

[Apple directory-access documentation](https://developer.apple.com/documentation/uikit/providing-access-to-directories) describes the picker/bookmark model. Native tests cover local roots with provider-style paths and stored bookmark resolution; actual iOS provider permission/revocation still needs device QA.

## Imported playlists

The scan pass discovers M3U/M3U8 files up to 2 MB. UTF-8/BOM and legacy Windows-1252 are supported. Comments are skipped; Windows separators normalized; relative paths are based on the manifest's directory. Local absolute/file URLs are accepted only inside the same selected root. Remote URLs/hosts and escapes are skipped without being opened.

Order and duplicates are preserved. A missing/excluded entry stays in unresolved-path feedback. The source ID and relative manifest path identify an imported playlist so rescans refresh the same record. Playlist/source removal never deletes music. Imported edits may be replaced on rescan; the UI says the file is the source. Manifests that disappear leave their last indexed playlist intact. Add the containing music folder or copy manifest and music together; importing a manifest alone cannot grant its referenced files.

Manifest and audio/LRC fingerprints skip unchanged parsing. Missing paths are canonicalized via the nearest existing parent, handling macOS /var aliases without dropping unresolved entries. Existing playlist records decode with optional import fields; database identity/schema stay unchanged.

## Artist photos

The user requested artist-image enrichment. Wikimedia's public [PageImages API](https://www.mediawiki.org/wiki/API:Pageimages) supplies only free image candidates (`pilicense=free`); [ImageInfo](https://www.mediawiki.org/wiki/API:Imageinfo) supplies creator, license, source and thumbnail. No key, account or SDK is used. Artist-name matches must be unique and musical; ambiguous/unmatched artists retain placeholders.

Artist rows initiate requests only when needed. The setting is enabled by default and stops new lookups when disabled; existing cached photos remain available offline. Requests send artist names plus normal HTTP/IP information, not audio, filenames or local paths. About and Settings disclose this exception to local music playback.

The ephemeral client identifies SoundBunker with version/project URL, serializes requests at most once a second, applies timeouts and size limits, and restricts requests/redirects to `en.wikipedia.org`, `upload.wikimedia.org` and the current `thumb.wikimedia.org` CDN. Thumbnails are resized to at most 160 pixels. A generated cache is periodically trimmed to 10 MB; cached images are reused, no-match results retry after a day, and network failures back off five minutes. Canceled lookups do not write a negative cache entry. There is no periodic background metadata job.

Photo records include creator, license and original file page. Long-press an artist row → Photo Credit shows full attribution/links and resizing notice. Source images retain their individual licenses. See [Wikimedia API etiquette](https://www.mediawiki.org/wiki/API:Etiquette).

## Project link

`scripts/update_project_metadata.py` reads origin, converts GitHub SSH/HTTPS to a credential-free browser URL, and bundles Resources/Project.json. Settings About and the About page open that link in the default browser. Project generation/build refreshes this metadata; tests validate remote conversion. No Git credentials are bundled.
