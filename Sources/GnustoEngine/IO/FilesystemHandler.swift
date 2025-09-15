import Foundation

// MARK: - FilesystemHandler Protocol

/// Handles filesystem operations for Gnusto games, including save files and transcripts.
///
/// This protocol enables dependency injection for filesystem operations, allowing
/// for easy testing with mock implementations that don't touch the actual filesystem.
public protocol FilesystemHandler: Sendable {
    /// The base directory where game files will be stored.
    ///
    /// This serves as the root location for all Gnusto game data. The standard
    /// implementation uses the user's home directory, but test implementations
    /// might use temporary directories or other locations.
    var baseDirectory: URL { get }
}

// MARK: - Standard Implementation

/// Production filesystem handler that uses the user's home directory.
///
/// Creates directories under `~/Gnusto/{game}/` for each game.
public struct StandardFilesystemHandler: FilesystemHandler {
    public let baseDirectory: URL

    public init() {
        baseDirectory = FileManager.default.homeDirectoryForCurrentUser
    }
}

// MARK: - Shared Utilities

extension FilesystemHandler {
    /// Returns the main Gnusto directory for the specified game.
    ///
    /// Creates the directory if it doesn't exist.
    ///
    /// - Parameter game: The game name (will be sanitized for filesystem use)
    /// - Returns: URL to the game's Gnusto directory
    /// - Throws: File system errors if directory creation fails
    public func gnustoDirectory(for game: String) throws -> URL {
        var sanitizedGame = game.replacing(/\W/, with: "")
        if sanitizedGame.isEmpty { sanitizedGame = "Unknown" }

        let gnustoDirectory = baseDirectory.appending(
            path: ["Gnusto", sanitizedGame].joined(separator: "/"),
            directoryHint: .isDirectory
        )

        if !FileManager.default.fileExists(atPath: gnustoDirectory.path()) {
            try FileManager.default.createDirectory(
                at: gnustoDirectory,
                withIntermediateDirectories: true
            )
        }

        return gnustoDirectory
    }

    /// Creates a URL for a save file with the given filename.
    ///
    /// The file will be located in the game's directory with the format: `{filename}.gnusto`
    ///
    /// - Parameters:
    ///   - game: The game name
    ///   - filename: The save filename (without extension)
    /// - Returns: URL to the save file
    /// - Throws: File system errors if directory creation fails
    public func saveFileURL(game: String, filename: String) throws -> URL {
        try gnustoDirectory(for: game).appending(path: "\(filename).gnusto")
    }

    /// Generates a timestamp string in the format `YYYY.MM.DD-HH.MM`.
    ///
    /// - Parameter date: The date to format (defaults to current date)
    /// - Returns: Formatted timestamp string suitable for file names
    public static func timestamp(for date: Date = .now) -> String {
        let components = Calendar(identifier: .gregorian)
            .dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
        return String(
            format: "%04d.%02d.%02d-%02d.%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }

    /// Creates a URL for a transcript file with a timestamp.
    ///
    /// The file will be located in the game's directory with the format:
    /// `transcript-{timestamp}.md`
    ///
    /// - Parameters:
    ///   - game: The game name
    ///   - date: The date to use for the timestamp (defaults to current date)
    /// - Returns: URL to the transcript file
    /// - Throws: File system errors if directory creation fails
    public func transcriptFileURL(game: String, date: Date = .now) throws -> URL {
        try gnustoDirectory(for: game).appending(
            path: "transcript-\(Self.timestamp(for: date)).md"
        )
    }
}
