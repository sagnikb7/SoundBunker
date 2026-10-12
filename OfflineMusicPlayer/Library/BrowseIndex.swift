import Foundation

/// Rebuilt when library data/policy changes, never for playback clock ticks.
struct BrowseIndex {
    let albums: [AlbumGroup]
    let artists: [String: [Track]]
    let genres: [String: [Track]]
    let artistNames: [String]
    let genreNames: [String]
    let recentTracks: [Track]
    let recentAlbums: [AlbumGroup]
    init(tracks: [Track]) {
        albums = AlbumGroup.make(tracks)
        artists = Dictionary(grouping: tracks, by: \.artist)
        genres = Dictionary(grouping: tracks, by: \.genre)
        artistNames = artists.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        genreNames = genres.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        recentTracks = tracks.sorted { $0.added > $1.added }
        recentAlbums = Array(albums.sorted { $0.added > $1.added }.prefix(8))
    }
}
