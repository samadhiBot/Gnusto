import GnustoEngine

/// # Roger Firth's Cloak of Darkness.
///
/// Roger Firth's **Cloak of Darkness** is a minimalist interactive fiction (IF) game created
/// in 1999 to serve as a cross-system demo for IF authoring engines. It is regarded as the
/// "Hello, world!" of interactive fiction, designed as a reference implementation to help
/// authors compare language features and basic capabilities across IF systems.
///
/// The game consists of:
///
/// - **Three rooms:** The Foyer (starting location, exits south and west), Cloakroom (west, contains
///                    a brass hook), and Bar (south, initially dark).
/// - **Three objects:** The player's black velvet cloak, the hook in the Cloakroom, and a message
///                      in the Bar.
/// - **Main puzzle:** To hang the cloak on the hook, which lights the Bar and reveals the message.
/// - **End condition:** Reading the message in the Bar (after lighting it) ends the game with either
///                      "You have won" or "You have lost," depending on how much the player disturbed
///                      the room while it was dark.
struct CloakOfDarkness: GameBlueprint {
    let title = "Cloak of Darkness"

    let abbreviatedTitle = "Cloak"

    let introduction = """
        A basic IF demonstration.

        Hurrying through the rainswept November night, you're glad to see the
        bright lights of the Opera House. It's surprising that there aren't more
        people about but, hey, what do you expect in a cheap demo game...?
        """

    let release = "0.0.3"

    let maximumScore = 2

    let player = Player(in: .foyer)

    let messenger: StandardMessenger

    init() {
        self.messenger = StandardMessenger()
    }

    // Note: All game content registration (items, locations, handlers, etc.)
    // is automatically handled by GnustoAutoWiringPlugin
}
