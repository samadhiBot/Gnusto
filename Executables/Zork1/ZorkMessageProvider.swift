import GnustoEngine

/// Message provider for Zork I that provides authentic ZIL-style messages.
///
/// This provider extends the standard messages with Zork-specific phrases,
/// particularly the iconic darkness messages that players expect from the
/// original Zork experience.
struct ZorkMessageProvider: MessageProvider {
    public let languageCode = "en"

    /// Standard provider for fallback to default messages
    private let standard = StandardMessageProvider()

    public func message(for key: MessageKey) -> String {
        switch key {
        case .nowDark:
            "You have moved into a dark place."

        case .roomIsDark:
            "It is pitch black. You are likely to be eaten by a grue."

        default:
            // Use standard provider for all other messages
            standard.message(for: key)
        }
    }
}
