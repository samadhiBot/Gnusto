import GnustoEngine

/// A faithful recreation of _Zork 1: The Great Underground Empire_ using the Gnusto Interactive
/// Fiction Engine.
///
/// This implementation follows the original ZIL source code to recreate the authentic player
/// experience while utilizing modern Swift architecture and the Gnusto engine's capabilities.
public struct Zork1: GameBlueprint {
    public let title = "Zork I: The Great Underground Empire"

    public let abbreviatedTitle = "Zork1"

    public let introduction = """
        ZORK I: The Great Underground Empire
        Copyright (c) 1981, 1982, 1983 Infocom, Inc. All rights reserved.
        ZORK is a registered trademark of Infocom, Inc.
        Revision 88 / Serial number 840726
        """

    public let release = "88"

    public let maximumScore = 350

    public let player = Player(in: .westOfHouse)

    // Declaring messenger and randomNumberGenerator allows you to inject
    // a deterministic random number generator for use in tests.
    public let messenger: StandardMessenger
    public let randomNumberGenerator: any RandomNumberGenerator & Sendable

    public init(
        rng: RandomNumberGenerator & Sendable = SystemRandomNumberGenerator()
    ) {
        self.randomNumberGenerator = rng
        self.messenger = ZorkMessenger(randomNumberGenerator: rng)
    }

    // Note: All game content registration (items, locations, handlers, etc.)
    // is automatically handled by GnustoAutoWiringPlugin
}

// MARK: - SwordBrightness

enum SwordBrightness: Codable, CustomStringConvertible, Sendable {
    case glowingBrightly
    case glowingFaintly
    case notGlowing

    var description: String {
        switch self {
        case .glowingBrightly: "Your sword is glowing very brightly."
        case .glowingFaintly: "Your sword is glowing with a faint blue glow."
        case .notGlowing: "Your sword is no longer glowing."
        }
    }
}

// MARK: - Custom IDs and Properties

extension Item {
    var isMonster: Bool {
        [.bat, .cyclops, .ghosts, .thief, .troll].contains(id)
    }
}

extension ItemProperty {
    /// The `SACREDBIT` is a Zork 1 specific flag whose job was to prevent the Thief from entering
    /// a location or stealing an object.
    ///
    /// In the Gnusto Engine translation it is only used to prevent item theft. For movement
    /// restriction the `.validLocations` property is set on the `.thief` item.
    static let isSacred = ItemProperty(
        id: ItemPropertyID(rawValue: "isSacred"),
        rawValue: true
    )
}

extension ItemPropertyID {
    static let isBurnedOut = ItemPropertyID("isBurnedOut")
    static let isSacred = ItemPropertyID(rawValue: "isSacred")
}
