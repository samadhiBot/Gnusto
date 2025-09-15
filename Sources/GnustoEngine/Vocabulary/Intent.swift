import Foundation

// MARK: - Backward Compatibility

/// Backward compatibility typealias for ActionID -> Intent migration
public typealias ActionID = Intent

/// Represents conceptual actions that can be performed in the game, independent of the specific verbs used.
///
/// While `Verb` represents the specific words players can type (like "turn", "light", "extinguish"),
/// `Intent` represents the conceptual action being performed (like `.lightSource` or `.extinguish`).
/// This separation allows game logic to check for conceptual actions without worrying about the
/// specific verb synonyms used.
///
/// For example, both "LIGHT LAMP" and "TURN ON LAMP" might represent the `.lightSource` action,
/// while "EXTINGUISH LAMP", "TURN OFF LAMP", and "DOUSE LAMP" might all represent the `.extinguish` action.
public enum Intent: String, CaseIterable, Sendable, Codable {
    // MARK: - Movement & Navigation

    /// Moving from one location to another
    case move

    /// Entering a location or container
    case enter

    /// Looking around or examining something
    case examine

    /// Looking around the current location
    case look

    // MARK: - Object Manipulation

    /// Taking or picking up an object
    case take

    /// Dropping or putting down an object
    case drop

    /// Putting an object inside a container
    case insert

    /// Removing an object from a container
    case remove

    /// Opening a container, door, or similar object
    case open

    /// Closing a container, door, or similar object
    case close

    // MARK: - Light & Power

    /// Activating a light source or powering something on
    case lightSource

    /// Extinguishing a light source or powering something off
    case extinguish

    // MARK: - Physical Actions

    /// Attempting to inflict irreversible destruction or damage on something
    case mung

    /// Pushing, moving, or physically manipulating an object
    case push

    /// Pulling an object
    case pull

    /// Turning or rotating an object
    case turn

    /// Climbing on or mounting something
    case climb

    /// Attacking or striking something
    case attack

    /// Defending from an attack
    case defend

    // MARK: - Communication & Information

    /// Asking someone about something
    case ask

    /// Telling someone something
    case tell

    /// Reading text or examining written material
    case read

    /// Listening to sounds
    case listen

    // MARK: - Game Meta Actions

    /// Checking inventory
    case inventory

    /// Getting help or instructions
    case help

    /// Saving the game
    case save

    /// Restoring a saved game
    case restore

    /// Quitting the game
    case quit

    /// Restarting the game
    case restart

    /// Waiting or passing time
    case wait

    /// Any meta action
    case meta

    // MARK: - Sensory Actions

    /// Touching or feeling an object
    case touch

    /// Smelling something
    case smell

    /// Tasting something
    case taste

    // MARK: - Complex Actions

    /// Giving an object to someone
    case give

    /// Wearing or putting on clothing/equipment
    case wear

    /// Locking something with a key
    case lock

    /// Unlocking something with a key
    case unlock

    /// Filling a container with liquid
    case fill

    /// Emptying a container
    case empty

    /// Pouring liquid from one container to another
    case pour

    /// Throwing an object
    case `throw`

    /// Cutting or slicing something
    case cut

    /// Tying something
    case tie

    /// Burning something
    case burn

    /// Digging
    case dig

    /// Drinking something
    case drink

    /// Eating something
    case eat

    /// Jumping
    case jump

    /// Swimming
    case swim

    /// Thinking about something
    case think

    /// Searching for something
    case search

    /// Sitting down or positioning oneself
    case sit

    /// Debug-related actions (development only)
    case debug
}
