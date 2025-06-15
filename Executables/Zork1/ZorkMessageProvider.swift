import GnustoEngine

/// Message provider for Zork I that provides authentic ZIL-style messages.
///
/// This provider extends the standard messages with Zork-specific phrases,
/// particularly the iconic darkness messages that players expect from the
/// original Zork experience.
final class ZorkMessageProvider: MessageProvider, @unchecked Sendable {
    override func nowDark() -> String {
        "You have moved into a dark place."
    }

    override func roomIsDark() -> String {
        "It is pitch black. You are likely to be eaten by a grue."
    }
}
