/// Represents various properties or flags that an item can possess.
public enum ItemProperty: String, Codable, CaseIterable, Sendable {
    case combatReady  // FIGHTBIT: Can participate in combat
    case container    // CONTBIT: Can hold other items
    case device       // DEVICEBIT: Can be turned on/off (ZILF specific)
    case door         // DOORBIT: Functions as a door
    case edible       // EDIBLEBIT: Can be eaten
    case equippable   // Can be equipped (e.g., weapon, shield)
    case female       // FEMALEBIT: Grammatically female
    case fixed        // Cannot be taken or moved (scenery)
    case flammable    // Can be burned
    case invisible    // INVISIBLE: Not normally seen
    case key          // Can be used to lock/unlock
    case lightSource  // LIGHTBIT: Provides light when active/on
    case lockable     // Can be locked/unlocked (needs `lockKey`)
    case locked       // LOCKEDBIT: Is locked
    case narticle     // NARTICLEBIT: Suppress default article ("a", "the")
    case ndesc        // NDESCBIT: Suppress automatic description in room contents
    case on           // ONBIT: Is currently switched on
    case open         // OPENBIT: Is currently open (for containers/doors)
    case openable     // OPENABLEBIT: Can be opened/closed by player
    case person       // PERSONBIT: An NPC or the player
    case plural       // PLURALBIT: Grammatically plural
    case read         // READBIT: Can be read (might have TEXT property)
    case readable     // Can be read (implies text content)
    case searchable   // SEARCHBIT: Can be searched
    case surface      // SURFACEBIT: Items can be placed *on* it
    case takable      // TAKEBIT: Can be picked up
    case touched      // TOUCHBIT: Player has interacted with it (used for brief mode descriptions)
    case transparent  // TRANSBIT: Contents are visible even if closed
    case trytake      // TRYTAKEBIT: Needs special check before taking
    case vowel        // VOWELBIT: Name starts with vowel (for "an")
    case wearable     // WEARBIT: Can be worn
    case worn         // WORNBIT: Is currently being worn
}
