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
    /// Throwing an object
    case `throw`

    /// Asking someone about something
    case ask

    /// Attacking or striking something
    case attack

    /// Burning something
    case burn

    /// Climbing on or mounting something
    case climb

    /// Closing a container, door, or similar object
    case close

    /// Cutting or slicing something
    case cut

    /// Debug-related actions (development only)
    case debug

    /// Defending from an attack
    case defend

    /// Digging
    case dig

    /// Drinking something
    case drink

    /// Dropping or putting down an object
    case drop

    /// Eating something
    case eat

    /// Emptying a container
    case empty

    /// Entering a location or container
    case enter

    /// Looking around or examining something
    case examine

    /// Extinguishing a light source or powering something off
    case extinguish

    /// Filling a container with liquid
    case fill

    /// Giving an object to someone
    case give

    /// Getting help or instructions
    case help

    /// Putting an object inside a container
    case insert

    /// Checking inventory
    case inventory

    /// Jumping
    case jump

    /// Activating a light source or powering something on
    case lightSource

    /// Listening to sounds
    case listen

    /// Locking something with a key
    case lock

    /// Looking around the current location
    case look

    /// Any meta action
    case meta

    /// Moving from one location to another
    case move

    /// Attempting to inflict irreversible destruction or damage on something
    case mung

    /// Opening a container, door, or similar object
    case open

    /// Pouring liquid from one container to another
    case pour

    /// Pulling an object
    case pull

    /// Pushing, moving, or physically manipulating an object
    case push

    /// Quitting the game
    case quit

    /// Reading text or examining written material
    case read

    /// Removing an object from a container
    case remove

    /// Restarting the game
    case restart

    /// Restoring a saved game
    case restore

    /// Saving the game
    case save

    /// Searching for something
    case search

    /// Sitting down or positioning oneself
    case sit

    /// Smelling something
    case smell

    /// Swimming
    case swim

    /// Taking or picking up an object
    case take

    /// Tasting something
    case taste

    /// Telling someone something
    case tell

    /// Thinking about something
    case think

    /// Tying something
    case tie

    /// Touching or feeling an object
    case touch

    /// Turning or rotating an object
    case turn

    /// Unlocking something with a key
    case unlock

    /// Waiting or passing time
    case wait

    /// Wearing or putting on clothing/equipment
    case wear
}
