/// Represents various properties or flags that an item can possess.
public enum ItemProperty: String, Codable, CaseIterable, Sendable {
    // Alphabetized cases based on ZIL flags seen so far
    case container = "container"      // CONTBIT: Can hold other items
    case device = "device"            // DEVICEBIT: Can be turned on/off (ZILF specific)
    case door = "door"                // DOORBIT: Functions as a door
    case edible = "edible"            // EDIBLEBIT: Can be eaten
    case female = "female"            // FEMALEBIT: Grammatically female
    case invisible = "invisible"      // INVISIBLE: Not normally seen
    case lightSource = "lightSource"  // LIGHTBIT: Provides light when active/on
    case locked = "locked"            // LOCKEDBIT: Is locked
    case narticle = "narticle"        // NARTICLEBIT: Suppress default article ("a", "the")
    case ndesc = "ndesc"              // NDESCBIT: Suppress automatic description in room contents
    case on = "on"                    // ONBIT: Is currently switched on
    case open = "open"                // OPENBIT: Is currently open (for containers/doors)
    case openable = "openable"        // OPENABLEBIT: Can be opened/closed by player
    case person = "person"            // PERSONBIT: An NPC or the player
    case plural = "plural"            // PLURALBIT: Grammatically plural
    case read = "read"                // READBIT: Can be read (might have TEXT property)
    case surface = "surface"          // SURFACEBIT: Items can be placed *on* it
    case takable = "takable"          // TAKEBIT: Can be picked up
    case touched = "touched"          // TOUCHBIT: Player has interacted with it (used for brief mode descriptions)
    case transparent = "transparent"  // TRANSBIT: Contents are visible even if closed
    case trytake = "trytake"          // TRYTAKEBIT: Needs special check before taking
    case vowel = "vowel"              // VOWELBIT: Name starts with vowel (for "an")
    case wearable = "wearable"        // WEARBIT: Can be worn
    case worn = "worn"                // WORNBIT: Is currently being worn
}
