import Foundation

/// Handles the "CUT" command and its synonyms (e.g., "SLICE", "CHOP").
///
/// The CUT verb allows players to attempt cutting objects with tools.
/// This handler checks for cutting tools (knives, swords, etc.), validates the target,
/// and provides appropriate responses based on ZIL behavior.
public struct CutActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.cut, .slice, .chop]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the CUT action by validating the target object and executing the cut attempt.
    ///
    /// This method first attempts to resolve the direct object (the item to be cut).
    /// If no valid target is found, it throws a "do what?" response.
    /// Otherwise, it delegates to the target item's response system to handle
    /// the cutting action appropriately based on the item type (object, character, or enemy).
    ///
    /// - Parameter context: The action context containing command details and game state
    /// - Returns: An ActionResult containing the appropriate response for the cut attempt
    /// - Throws: ActionResponse.doWhat if no valid target object can be resolved
    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let targetItem = try await context.itemDirectObject(
                playerMessage: context.msg.cutPlayer()
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        return try await ActionResult(
            targetItem.response(
                object: context.msg.cutItem,
                character: context.msg.cutCharacter,
                enemy: context.msg.cutEnemy
            )
        )
    }
}
