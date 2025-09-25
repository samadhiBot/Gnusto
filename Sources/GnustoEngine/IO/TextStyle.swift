/// Represents stylistic hints for text output.
///
/// The `IOHandler` implementation can choose how (or if) to interpret these hints.
public enum TextStyle: Sendable {
    /// Debugging information.
    case debug

    /// Emphasized text (e.g., italics).
    case emphasis

    /// Text representing user input.
    case input

    /// Normal paragraph text.
    case normal

    /// Preformatted text (e.g., for ASCII art, preserve spacing).
    case preformatted

    /// Text for the top status line.
    case statusLine

    /// Strongly emphasized text (e.g., bold).
    case strong
}
