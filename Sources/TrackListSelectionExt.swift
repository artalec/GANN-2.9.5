import Foundation

extension AppModel {
    func selectAndHighlightTrack(_ trackID: UUID, in playlistID: UUID) {
        selectedPlaylistID = playlistID
        // Wait briefly for playlist to load then select track
        DispatchQueue.main.async {
            self.selection.selectSingle(trackID)
        }
    }
}
