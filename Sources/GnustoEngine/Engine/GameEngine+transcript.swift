import Foundation

extension GameEngine {
    func startTranscript() async throws {
        try await ioHandler.setTranscriptRecorder(
            TranscriptRecorder(transcriptURL: transcriptURL, title: title)
        )
    }

    func stopTranscript() async {
        await ioHandler.clearTranscriptRecorder()
    }

    var transcriptURL: URL {
        get throws {
            try filesystemHandler.transcriptFileURL(
                game: abbreviatedTitle,
                date: .now
            )
        }
    }
}
