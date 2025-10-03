import Foundation

extension GameEngine {
    /// Starts recording a transcript for the current game session.
    /// - Throws: An error if the transcript file URL cannot be generated or the recorder
    ///           cannot be set.
    func startTranscript() async throws {
        // Generate the transcript URL once when starting
        let url = try filesystemHandler.transcriptFileURL(
            game: abbreviatedTitle,
            date: .now
        )

        try await ioHandler.setTranscriptRecorder(
            TranscriptRecorder(transcriptURL: url, title: title)
        )
    }

    /// Stops recording the transcript for the current game session.
    /// This will clear the active transcript recorder.
    func stopTranscript() async {
        await ioHandler.clearTranscriptRecorder()
    }

    /// Returns the current transcript URL if a transcript is active.
    var transcriptURL: URL? {
        get async {
            await ioHandler.transcriptURL
        }
    }
}
