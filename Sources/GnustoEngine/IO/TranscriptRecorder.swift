import Foundation
import Logging

/// A simple file recorder for transcript operations.
///
/// The TranscriptRecorder handles writing transcript data to a file.
public final class TranscriptRecorder: Sendable {
    /// The URL where the transcript file is written.
    public let transcriptURL: URL

    /// The file handle used for writing transcript data.
    private let fileHandle: FileHandle

    /// Internal logger for engine messages, warnings, and errors.
    private let logger = Logger(label: "com.samadhibot.Gnusto.TranscriptRecorder")

    /// Creates a new transcript recorder that writes to the specified URL.
    ///
    /// - Parameters:
    ///   - transcriptURL: The URL where the transcript file should be written
    ///   - title: The game title to include in the transcript header
    public init(
        transcriptURL: URL,
        title: String
    ) throws {
        let started = Date()
        self.transcriptURL = transcriptURL

        FileManager.default.createFile(
            atPath: transcriptURL.path(),
            contents: Data(
                """
                \(title)
                Transcript started: \(started.formatted())

                """.utf8
            )
        )

        self.fileHandle = try FileHandle(forWritingTo: transcriptURL)
    }

    deinit {
        do {
            try write(
                """

                Transcript ended.

                """
            )
            try fileHandle.close()
        } catch {
            logger.error("Warning: Failed to close transcript file: \(error)")
        }
    }

    func write(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw ActionResponse.internalEngineError("Failed to convert '\(string)' to data")
        }
        try fileHandle.write(contentsOf: data)
    }
}
