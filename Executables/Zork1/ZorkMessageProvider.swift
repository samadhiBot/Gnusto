import GnustoEngine
import Logging

/// Messenger for Zork I that provides authentic ZIL-style messages.
///
/// This messenger extends the standard messages with Zork-specific phrases,
/// particularly the iconic darkness messages that players expect from the
/// original Zork experience.
public class ZorkMessageProvider: StandardMessenger, @unchecked Sendable {
    let logger = Logger(label: "com.samadhibot.Gnusto.StandardMessenger")

    public override func nowDark() -> String {
        output("You have moved into a dark place.")
    }

    public override func roomIsDark() -> String {
        output("It is pitch black. You are likely to be eaten by a grue.")
    }

    public override func containerContents(_ container: String, contents: String) -> String {
        output("\(container) contains \(contents).")
    }
}
