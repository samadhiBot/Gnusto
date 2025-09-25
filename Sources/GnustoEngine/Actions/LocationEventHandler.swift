import Foundation

/// A container for custom game logic that responds to specific events occurring in relation
/// to a `Location`.
///
/// You define a `LocationEventHandler` by providing a closure that takes either:
/// - A `GameEngine` and `LocationEvent` as input (legacy API)
/// - A `LocationEventContext` as input (modern API)
///
/// This closure can then execute arbitrary game logic and optionally return an `ActionResult`
/// to influence or override the default game flow.
///
/// Location event handlers are typically registered with the `GameBlueprint` to associate
/// specific locations with custom behaviors triggered by game events.
public struct LocationEventHandler: Sendable {
    /// The closure that implements the custom event handling logic.
    /// This is not directly accessed; you provide it during initialization.
    let handle: @Sendable (GameEngine, LocationEvent) async throws -> ActionResult?

    /// Initializes a `LocationEventHandler` with a legacy handler closure.
    ///
    /// - Parameter handler: A closure that will be invoked when a relevant `LocationEvent` occurs.
    ///   The closure receives:
    ///   - `engine`: The current `GameEngine` instance, allowing interaction with game state.
    ///   - `event`: The specific `LocationEvent` that triggered this handler.
    ///   It can throw an error if processing fails, and can optionally return an `ActionResult`
    ///   to modify or conclude the current game action (e.g., printing a message, ending the turn).
    ///   If `nil` is returned, the game typically proceeds with its default behavior.
    public init(
        _ handler: @Sendable @escaping (GameEngine, LocationEvent) async throws -> ActionResult?
    ) {
        self.handle = handler
    }

    /// Initializes a `LocationEventHandler` with a result builder that provides declarative
    /// event matching.
    ///
    /// This is the recommended approach that eliminates the need for nested `event.match`
    /// closures.
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location this handler is for
    ///   - matchers: A result builder that creates a list of event matchers
    ///
    /// Example usage:
    /// ```swift
    /// var locationEventHandlers: [LocationID: LocationEventHandler] {
    ///     [
    ///         .bar: LocationEventHandler(for: .bar) {
    ///             before(.move) { context, command in
    ///                 if !await context.location.isLit {
    ///                     ActionResult("Blundering around in the dark isn't a good idea!")
    ///                 } else {
    ///                     nil
    ///                 }
    ///             }
    ///             onEnter { context in
    ///                 ActionResult("You feel a chill as you enter.")
    ///             }
    ///         }
    ///     ]
    /// }
    /// ```
    public init(
        for locationID: LocationID,
        @LocationEventMatcherBuilder _ matchers:
            @Sendable @escaping () async throws -> [LocationEventMatcher]
    ) {
        self.handle = { engine, event in
            let location = await engine.location(locationID)
            let context = LocationEventContext(event: event, location: location, engine: engine)

            let matcherList = try await matchers()
            for matcher in matcherList {
                if let result = try await matcher(context) {
                    return result
                }
            }
            return nil
        }
    }
}

/// Represents the specific moments or triggers that can activate a `LocationEventHandler`.
///
/// Note: The ZIL concept of "Room Actions" (often triggered by messages like `M-LOOK`,
/// `M-FLASH`) is analogous to `LocationEventHandler` in Gnusto. Some event types here
/// directly map to those concepts, while others provide more general hooks.
public enum LocationEvent: Sendable {
    /// Triggered after the game engine has processed the player's command for the current turn,
    /// while the player is in a location that has this event handler.
    ///
    /// The associated `Command` is the one the player entered.
    /// This allows the location to react to the outcome of the turn or perform cleanup actions.
    case afterTurn(Command)

    /// Triggered before the game engine processes the player's command for the current turn,
    /// while the player is in a location that has this event handler.
    ///
    /// The associated `Command` is the one the player has just entered.
    /// Your handler can inspect this command and potentially return an `ActionResult` to
    /// preempt or alter the default command processing.
    case beforeTurn(Command)

    /// Triggered when the player successfully enters the location that has this event handler.
    /// This typically occurs after any "look" action or movement that results in the player
    /// arriving in this location.
    case onEnter
}

// MARK: - Event Matching Result Builder

/// A type alias for context-aware location event matcher functions.
public typealias LocationEventMatcher = (LocationEventContext) async throws -> ActionResult?

/// Result builder for creating clean, declarative location event handling.
///
/// This builder allows you to write location event handlers in a declarative way:
/// ```swift
/// .bar: LocationEventHandler(for: .bar) {
///     before(.move) { context, command in
///         if !await context.location.isLit {
///             ActionResult("Blundering around in the dark isn't a good idea!")
///         } else {
///             nil
///         }
///     }
///     onEnter { context in
///         ActionResult("You feel a chill as you enter.")
///     }
/// }
/// ```
@resultBuilder
public struct LocationEventMatcherBuilder {
    /// Builds a block of location event matchers into an array.
    ///
    /// This is the core method of the `LocationEventMatcherBuilder` result builder that
    /// combines multiple `LocationEventMatcher` functions into a single array for processing
    /// by the location event handler.
    ///
    /// - Parameter matchers: A variadic list of `LocationEventMatcher` functions created by
    ///   functions like `beforeTurn()`, `afterTurn()`, and `onEnter()`
    /// - Returns: An array containing all the provided matchers
    public static func buildBlock(_ matchers: LocationEventMatcher...) -> [LocationEventMatcher] {
        Array(matchers)
    }
}

// MARK: - Location Event Matcher Builder Functions

/*
 Location Event Execution Flow:

 ┌─────────────────────────────────────────────────────────────────┐
 │ Player enters command: "take lamp"                              │
 └─────────────────────────────────────────────┬───────────────────┘
                                               │
                                               ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 1. beforeTurn() - Called BEFORE action processing              │
 │    • Can intercept and override normal command processing       │
 │    • If returns ActionResult, command processing stops          │
 │    • Example: Block movement in dark rooms                      │
 └─────────────────────────────────────────────┬───────────────────┘
                                               │
                                               ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 2. Main Action Handler Processing                               │
 │    • TakeActionHandler.process() executes                       │
 │    • State changes applied                                      │
 │    • Message printed: "Taken."                                  │
 └─────────────────────────────────────────────┬───────────────────┘
                                               │
                                               ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 3. afterTurn() - Called AFTER action completed                 │
 │    • Cannot prevent the action (already happened)               │
 │    • Can add follow-up effects or ambient responses             │
 │    • Example: "You hear rustling in the bushes."                │
 └─────────────────────────────────────────────┬───────────────────┘
                                               │
                                               ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 4. onEnter() - Called ONLY when player moves to new location    │
 │    • Fires during movement detection phase                      │
 │    • One-time location arrival events                           │
 │    • Example: Trap triggers, NPC greets player                  │
 └─────────────────────────────────────────────────────────────────┘

 Note: onEnter() only fires for location changes, not every turn.
       beforeTurn() and afterTurn() fire every turn while in the location.
*/

/// Creates a location event matcher for **beforeTurn** events with any of the specified intents.
///
/// **Timing**: Called at the very beginning of command execution, before any action handlers run.
/// **Purpose**: Can intercept and potentially override normal command processing.
/// **Can Block Actions**: Yes - if it returns an `ActionResult`, further command processing stops.
///
/// - Parameters:
///   - intents: The command intents to match against (e.g., `.move`, `.take`, `.examine`)
///   - result: The closure to execute if any intent matches, receiving the context and command
/// - Returns: A LocationEventMatcher that can be used in the result builder
///
/// Example:
/// ```swift
/// beforeTurn(.move) { context, command in
///     if !await context.location.isLit {
///         ActionResult("Blundering around in the dark isn't a good idea!")
///     } else {
///         nil  // Allow normal movement processing
///     }
/// }
/// ```
public func beforeTurn(
    _ intents: Intent...,
    result: @escaping (LocationEventContext, Command) async throws -> ActionResult?
) -> LocationEventMatcher {
    { context in
        guard
            case .beforeTurn(let command) = context.event,
            command.matchesIntents(intents)
        else {
            return nil
        }
        return try await result(context, command)
    }
}

/// Creates a location event matcher for **afterTurn** events with any of the specified intents.
///
/// **Timing**: Called after the main action handler has completed successfully.
/// **Purpose**: React to what just happened or perform cleanup/ambient actions.
/// **Can Block Actions**: No - the main action already happened, this is just for follow-up effects.
///
/// - Parameters:
///   - intents: The command intents to match against (e.g., `.move`, `.take`, `.examine`).
///              If no intents specified, matches all commands.
///   - result: The closure to execute for matching afterTurn events, receiving the context and command
/// - Returns: A LocationEventMatcher that can be used in the result builder
///
/// Example:
/// ```swift
/// afterTurn { context, command in
///     // Ambient sounds after any action in this forest location
///     ActionResult("You hear rustling in the distant bushes.")
/// }
///
/// afterTurn(.take) { context, command in
///     // Specific reaction to taking items in this location
///     ActionResult("The shopkeeper eyes you suspiciously.")
/// }
/// ```
public func afterTurn(
    _ intents: Intent...,
    result: @escaping (LocationEventContext, Command) async throws -> ActionResult?
) -> LocationEventMatcher {
    { context in
        guard
            case .afterTurn(let command) = context.event,
            command.matchesIntents(intents)
        else {
            return nil
        }
        return try await result(context, command)
    }
}

/// Creates a location event matcher for **onEnter** events.
///
/// **Timing**: Called only when the player moves into this location (not every turn).
/// **Purpose**: Handle one-time events that occur when arriving at a location.
/// **Can Block Actions**: No - the movement already happened, this is just for arrival effects.
///
/// This is the only location event that truly relates to "entering" - it fires during the
/// movement detection phase after successful location changes.
///
/// - Parameter result: The closure to execute for onEnter events, receiving only the context
///                    (no command, since this isn't tied to a specific player command)
/// - Returns: A LocationEventMatcher that can be used in the result builder
///
/// Example:
/// ```swift
/// onEnter { context in
///     // One-time trap that triggers when first entering
///     if !await context.engine.hasFlag(.cellarTrapTriggered) {
///         return ActionResult(
///             "The trap door crashes shut, and you hear someone barring it!",
///             context.engine.setFlag(.cellarTrapTriggered),
///             context.item(.trapDoor).clearFlag(.isOpen)
///         )
///     }
///     return nil
/// }
///
/// onEnter { context in
///     // NPC greeting when entering their domain
///     ActionResult("The wizard looks up from his spellbook and nods at you.")
/// }
/// ```
public func onEnter(
    result: @escaping (LocationEventContext) async throws -> ActionResult?
) -> LocationEventMatcher {
    { context in
        if case .onEnter = context.event {
            try await result(context)
        } else {
            nil
        }
    }
}
