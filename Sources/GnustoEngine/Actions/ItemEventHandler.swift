import Foundation

/// A container for custom game logic that responds to specific events occurring in relation
/// to an `Item`.
///
/// You define an `ItemEventHandler` by providing a closure that takes either:
/// - A `GameEngine` and `ItemEvent` as input (legacy API)
/// - An `ItemEventContext` as input (modern API)
///
/// This closure can then execute arbitrary game logic and optionally return an `ActionResult`
/// to influence or override the default game flow.
///
/// Item event handlers are typically registered with the `GameBlueprint` to associate
/// specific items with custom behaviors triggered by game events.
public struct ItemEventHandler: Sendable {
    /// The closure that implements the custom event handling logic.
    /// This is not directly accessed; you provide it during initialization.
    let handle: @Sendable (GameEngine, ItemEvent) async throws -> ActionResult?

    /// Initializes an `ItemEventHandler` with a legacy handler closure.
    ///
    /// - Parameter handler: A closure that will be invoked when a relevant `ItemEvent` occurs.
    ///   The closure receives:
    ///   - `engine`: The current `GameEngine` instance, allowing interaction with game state.
    ///   - `event`: The specific `ItemEvent` that triggered this handler.
    ///   It can throw an error if processing fails, and can optionally return an `ActionResult`
    ///   to modify or conclude the current game action (e.g., printing a message, ending the turn).
    ///   If `nil` is returned, the game typically proceeds with its default behavior.
    public init(
        _ handler: @Sendable @escaping (GameEngine, ItemEvent) async throws -> ActionResult?
    ) {
        self.handle = handler
    }

    /// Initializes an `ItemEventHandler` with a result builder that provides declarative event matching.
    ///
    /// This is the recommended modern approach that eliminates the need for nested `event.match` closures.
    ///
    /// - Parameters:
    ///   - itemID: The ID of the item this handler is for
    ///   - matchers: A result builder that creates a list of event matchers
    ///
    /// Example usage:
    /// ```swift
    /// var itemEventHandlers: [ItemID: ItemEventHandler] {
    ///     [
    ///         .lamp: ItemEventHandler(for: .lamp) {
    ///             before(.turnOn) { context, command in
    ///                 if await context.item.hasFlag(.isBroken) {
    ///                     ActionResult("The lamp is broken.")
    ///                 } else {
    ///                     ActionResult(
    ///                         "The lamp flickers to life.",
    ///                         context.item.setFlag(.isOn)
    ///                     )
    ///                 }
    ///             }
    ///             afterTurn { context, command in
    ///                 ActionResult("After turn action.")
    ///             }
    ///         }
    ///     ]
    /// }
    /// ```
    public init(
        for itemID: ItemID,
        @ItemEventMatcherBuilder _ matchers:
            @Sendable @escaping () async throws -> [ItemEventMatcher]
    ) {
        self.handle = { engine, event in
            let item = await engine.item(itemID)
            let context = ItemEventContext(event: event, item: item, engine: engine)

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

/// Represents the specific moments or triggers that can activate an `ItemEventHandler` for an item.
public enum ItemEvent: Sendable {
    /// Triggered after the game engine has processed the player's command for the current turn,
    /// specifically in the context of an item that has this event handler.
    ///
    /// The associated `Command` is the one the player entered.
    /// This allows the item to react to the outcome of the turn or perform cleanup actions.
    case afterTurn(Command)

    /// Triggered before the game engine processes the player's command for the current turn,
    /// specifically in the context of an item that has this event handler.
    ///
    /// The associated `Command` is the one the player has just entered.
    /// Your handler can inspect this command and potentially return an `ActionResult` to
    /// preempt or alter the default command processing for this item.
    case beforeTurn(Command)
}

// MARK: - Event Matching Result Builder

/// A type alias for context-aware item event matcher functions.
public typealias ItemEventMatcher = (ItemEventContext) async throws -> ActionResult?

/// Result builder for creating clean, declarative item event handling.
///
/// This builder allows you to write event handlers in a declarative way:
/// ```swift
/// .lamp: ItemEventHandler(for: .lamp) {
///     before(.turnOn) { context, command in
///         if await context.item.hasFlag(.isBroken) {
///             ActionResult("The lamp is broken.")
///         } else {
///             ActionResult(
///                 "The lamp flickers to life.",
///                 context.item.setFlag(.isOn)
///             )
///         }
///     }
///     afterTurn { context, command in
///         ActionResult("After turn action.")
///     }
/// }
/// ```
@resultBuilder
public struct ItemEventMatcherBuilder {
    /// Builds an array of ItemEventMatcher from a sequence of matchers.
    ///
    /// This is the core building block method for the result builder that combines
    /// multiple event matchers (created by `before()` and `after()` functions) into
    /// a single array that can be processed by the ItemEventHandler.
    ///
    /// - Parameter matchers: A variadic list of ItemEventMatcher functions
    /// - Returns: An array containing all the provided matchers
    public static func buildBlock(_ matchers: ItemEventMatcher...) -> [ItemEventMatcher] {
        Array(matchers)
    }
}

// MARK: - Item Event Matcher Builder Functions

/*
 Item Event Execution Flow:

 ┌─────────────────────────────────────────────────────────────────┐
 │ Player enters command: "take lamp"                              │
 └─────────────────────────────────────────┬───────────────────────┘
                                           │
                                           ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 1. Item before() Events - For ALL relevant items                │
 │    • Items in current location + player inventory               │
 │    • Called BEFORE action processing                            │
 │    • Can intercept and override normal command processing       │
 │    • If returns ActionResult, command processing stops          │
 │    • Example: Broken lamp prevents turning on                   │
 └─────────────────────────────────────────┬───────────────────────┘
                                           │
                                           ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 2. Location beforeTurn Events                                   │
 │    • Current location's beforeTurn handler                      │
 │    • Can also block command processing                          │
 └─────────────────────────────────────────┬───────────────────────┘
                                           │
                                           ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 3. Main Action Handler Processing                               │
 │    • TakeActionHandler.process() executes                       │
 │    • State changes applied                                      │
 │    • Message printed: "Taken."                                  │
 └─────────────────────────────────────────┬───────────────────────┘
                                           │
                                           ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 4. Item after() Events - For command's target items             │
 │    • Direct object (lamp) and indirect object handlers          │
 │    • Called AFTER action completed                              │
 │    • Cannot prevent the action (already happened)               │
 │    • Can add follow-up effects                                  │
 │    • Example: Lamp hums when turned on                          │
 └─────────────────────────────────────────┬───────────────────────┘
                                           │
                                           ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │ 5. Location afterTurn Events                                    │
 │    • Current location's afterTurn handler                       │
 │    • Additional location-based reactions                        │
 └─────────────────────────────────────────────────────────────────┘

 Key Differences:
 • before() fires for ALL relevant items (scope-based)
 • after() fires only for items directly involved in the command
 • before() can block actions, after() can only react to them
*/

/// Creates an item event matcher for **beforeTurn** events with any of the specified intents.
///
/// **Timing**: Called at the very beginning of command execution, before any action handlers run.
/// **Scope**: Fires for ALL items that have this handler in the player's current location and inventory.
/// **Purpose**: Can intercept and potentially override normal command processing.
/// **Can Block Actions**: Yes - if it returns an `ActionResult`, further command processing stops.
///
/// - Parameters:
///   - intents: The command intents to match against (e.g., `.turnOn`, `.take`, `.examine`).
///              If no intents specified, matches all commands.
///   - result: The closure to execute if any intent matches, receiving the context and command
/// - Returns: An ItemEventMatcher that can be used in the result builder
///
/// Example:
/// ```swift
/// before(.turnOn) { context, command in
///     if await context.item.hasFlag(.isBroken) {
///         ActionResult("The lamp is broken and won't turn on.")
///     } else {
///         nil  // Allow normal turn-on processing
///     }
/// }
///
/// before { context, command in
///     // React to any command involving this item
///     if command.verb == .examine {
///         ActionResult("This item glows mysteriously when examined.")
///     } else {
///         nil
///     }
/// }
/// ```
public func before(
    _ intents: Intent...,
    result: @escaping (ItemEventContext, Command) async throws -> ActionResult?
) -> ItemEventMatcher {
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

/// Creates an item event matcher for **afterTurn** events with any of the specified intents.
///
/// **Timing**: Called after the main action handler has completed successfully.
/// **Scope**: Fires only for items directly involved in the command (direct/indirect objects).
/// **Purpose**: React to what just happened or perform follow-up effects specific to this item.
/// **Can Block Actions**: No - the main action already happened, this is just for follow-up effects.
///
/// - Parameters:
///   - intents: The command intents to match against (e.g., `.turnOn`, `.take`, `.examine`).
///              If no intents specified, matches all commands involving this item.
///   - result: The closure to execute for matching afterTurn events, receiving the context and command
/// - Returns: An ItemEventMatcher that can be used in the result builder
///
/// Example:
/// ```swift
/// after(.turnOn) { context, command in
///     // Lamp-specific reaction after being turned on
///     ActionResult("The lamp hums quietly and casts dancing shadows.")
/// }
///
/// after(.take) { context, command in
///     // Item-specific reaction after being taken
///     if await context.item.hasFlag(.isCursed) {
///         ActionResult("As you pick it up, the cursed amulet grows cold.")
///     } else {
///         nil
///     }
/// }
///
/// after { context, command in
///     // React to any command that directly involved this item
///     ActionResult("The magical item pulses with energy after being touched.")
/// }
/// ```
public func after(
    _ intents: Intent...,
    result: @escaping (ItemEventContext, Command) async throws -> ActionResult?
) -> ItemEventMatcher {
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
