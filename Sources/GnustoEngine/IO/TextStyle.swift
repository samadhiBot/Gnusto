/// Represents stylistic hints for text output.
///
/// The `IOHandler` implementation can choose how (or if) to interpret these hints.
public enum TextStyle: Sendable {
    /// Normal paragraph text.
    case normal

    /// Emphasized text (e.g., italics).
    case emphasis

    /// Strongly emphasized text (e.g., bold).
    case strong

    /// Preformatted text (e.g., for ASCII art, preserve spacing).
    case preformatted

    /// Text for the top status line.
    case statusLine

    /// Text representing user input.
    case input

    /// Debugging information.
    case debug
}
