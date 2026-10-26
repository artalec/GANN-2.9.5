import SwiftUI

struct SearchResultItem: Identifiable, Hashable {
    enum Kind: Hashable {
        case playlist(Playlist)
        case track(Playlist, Track)
    }
    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    let playlistColor: RGBAColor
}

struct SearchPopoverView: View {
    let query: String
    let playlists: [Playlist]
    let onSelectPlaylist: (Playlist) -> Void
    let onSelectTrack: (Playlist, Track) -> Void

    var results: [SearchResultItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }

        var items: [SearchResultItem] = []
        for pl in playlists {
            if pl.name.lowercased().contains(q) {
                items.append(SearchResultItem(
                    kind: .playlist(pl),
                    title: pl.name,
                    subtitle: "Плейлист · \(pl.tracks.count) трек(ов)",
                    playlistColor: pl.color
                ))
            }
            for tr in pl.tracks {
                if tr.name.lowercased().contains(q) {
                    items.append(SearchResultItem(
                        kind: .track(pl, tr),
                        title: tr.name,
                        subtitle: "Плейлист: \(pl.name)",
                        playlistColor: tr.color ?? pl.color
                    ))
                }
            }
        }
        return items
    }

    var body: some View {
        Group {
            let res = results
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                EmptyView()
            } else if res.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("Ничего не найдено")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            } else {
                List(res) { item in
                    Button {
                        switch item.kind {
                        case .playlist(let pl):
                            onSelectPlaylist(pl)
                        case .track(let pl, let tr):
                            onSelectTrack(pl, tr)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.playlistColor.swiftUIColor)
                                .frame(width: 4, height: 18)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text(item.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()

                            Image(systemName: caseIcon(item.kind))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
    }

    private func caseIcon(_ kind: SearchResultItem.Kind) -> String {
        switch kind {
        case .playlist: return "list.bullet"
        case .track: return "music.note"
        }
    }
}
