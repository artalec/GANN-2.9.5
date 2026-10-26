import Foundation

/// Сохранение состояния приложения и экспорт/импорт плейлистов.
struct StorageManager {

    static let shared = StorageManager()

    private let fileManager = FileManager.default

    private var directory: URL {
        Self.appSupportDirectory()
    }

    /// Папка данных приложения: ~/Library/Application Support/GANN Player.
    /// Одноразово копирует appstate.json и recovery.log из старой папки DJPlayer,
    /// чтобы плейлисты и журнал не пропали после переименования.
    static func appSupportDirectory() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent("GANN Player", isDirectory: true)
        let legacy = base.appendingPathComponent("DJPlayer", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        if fm.fileExists(atPath: legacy.path) {
            for name in ["appstate.json", "recovery.log"] {
                let src = legacy.appendingPathComponent(name)
                let dst = dir.appendingPathComponent(name)
                if fm.fileExists(atPath: src.path), !fm.fileExists(atPath: dst.path) {
                    try? fm.copyItem(at: src, to: dst)
                }
            }
        }
        return dir
    }

    private var stateURL: URL {
        directory.appendingPathComponent("appstate.json")
    }

    // Путь можно вывести в консоль для отладки.
    var statePath: String { stateURL.path }

    // MARK: - Состояние приложения

    private static let writeQueue = DispatchQueue(label: "GANNPlayer.storage", qos: .utility)

    /// Синхронная запись. Ждёт завершения фоновых записей, поэтому порядок сохраняется
    /// и последнее состояние (например, при выходе) гарантированно попадает на диск.
    func save(_ state: AppState) {
        Self.writeQueue.sync { self.write(state) }
    }

    /// Фоновая запись для автосохранения: кодирование JSON не блокирует интерфейс.
    func saveInBackground(_ state: AppState) {
        Self.writeQueue.async { self.write(state) }
    }

    private func write(_ state: AppState) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            NSLog("GANN Player: не удалось сохранить состояние — \(error.localizedDescription)")
        }
    }

    func load() -> AppState {
        guard fileManager.fileExists(atPath: stateURL.path) else {
            return AppState.fresh()
        }
        do {
            let data = try Data(contentsOf: stateURL)
            var state = try JSONDecoder().decode(AppState.self, from: data)
            if state.playlists.isEmpty {
                state = AppState.fresh()
            }
            return state
        } catch {
            NSLog("GANN Player: не удалось прочитать состояние — \(error.localizedDescription)")
            return AppState.fresh()
        }
    }

    // MARK: - Экспорт / импорт плейлистов

    func export(_ playlist: Playlist, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(playlist)
        try data.write(to: url, options: .atomic)
    }

    func `import`(from url: URL) throws -> Playlist {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Playlist.self, from: data)
    }

    func resetAll() {
        try? fileManager.removeItem(at: stateURL)
    }
}
