import Foundation

/// Defines the interface for all input and output operations within the Gnusto game engine.
///
/// The `IOHandler` protocol abstracts the means by which the game communicates with
/// the player. This allows different frontends (e.g., a simple console, a graphical UI,
/// or even a networked client) to be used with the same core game logic.
///
/// Game developers typically do not implement this protocol directly unless creating a custom
/// frontend for their game. The engine will be initialized with a concrete `IOHandler`
/// (like `ConsoleIOHandler`) which manages the actual I/O operations.
///
/// All methods of an `IOHandler` are expected to be called on the main actor.
@MainActor
public protocol IOHandler: Sendable {
    /// The current transcript recorder, if one is active.
    var transcriptRecorder: TranscriptRecorder? { get set }

    /// Returns the current transcript URL if a transcript is active.
    var transcriptURL: URL? { get }

    /// Sets the transcript recorder from a non-main actor context.
    mutating func setTranscriptRecorder(_ recorder: TranscriptRecorder)

    /// Clears the transcript recorder from a non-main actor context.
    mutating func clearTranscriptRecorder()

    // --- Output Methods ---

    /// Displays a string of text to the player.
    ///
    /// - Parameters:
    ///   - markdown: The markdown text to display.
    ///   - style: A hint for the desired text style (implementation specific).
    ///   - newline: Whether to append a newline character after the text (defaults to true).
    func print(_ markdown: String, style: TextStyle, newline: Bool)

    /// Displays the top status line (typically Room Name and Score/Turns).
    ///
    /// Implementations are responsible for formatting this information appropriately.
    ///
    /// - Parameters:
    ///   - roomName: The name of the current room.
    ///   - score: The current score.
    ///   - turns: The current turn count.
    func showStatusLine(roomName: String, score: Int, turns: Int)

    /// Clears the main output area (excluding potentially the status line).
    func clearScreen()

    // --- Input Methods ---

    /// Reads a line of input from the player.
    ///
    /// This function should block until input is received.
    ///
    /// - Parameter prompt: A prompt string to display before waiting for input (e.g., "> ").
    /// - Returns: The input string entered by the player, or nil if input fails or is EOF.
    func readLine(prompt: String) -> String?

    // --- Lifecycle Methods ---

    /// Performs any necessary setup before interaction begins (e.g., initializing UI).
    func setup()

    /// Performs any necessary cleanup after interaction ends (e.g., restoring terminal state).
    func teardown()
}

// Default implementations for convenience print methods
extension IOHandler {
    /// Default implementation that returns the transcript URL from the active recorder.
    public var transcriptURL: URL? {
        transcriptRecorder?.transcriptURL
    }

    /// Prints a Markdown string to the output using the `.normal` style and appends a newline.
    public func print(_ markdown: String) {
        print(markdown, style: .normal, newline: true)
    }

    /// Prints a Markdown string to the output using the specified `style` and appends a newline.
    public func print(_ markdown: String, style: TextStyle) {
        print(markdown, style: style, newline: true)
    }

    /// Default implementation of setTranscriptRecorder that simply clears the property.
    public mutating func clearTranscriptRecorder() {
        transcriptRecorder = nil
    }

    /// Default implementation of setTranscriptRecorder that simply sets the property.
    public mutating func setTranscriptRecorder(_ recorder: TranscriptRecorder) {
        transcriptRecorder = recorder
    }
}
