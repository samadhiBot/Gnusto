import Foundation

/// Handles the "JUMP" command and its synonyms (e.g., "LEAP", "HOP").
/// Implements jumping behavior following ZIL patterns.
public struct JumpActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
        .match(.verb, .over, .directObject),
    ]

    public let synonyms: [Verb] = [.jump, .leap, .hop]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "JUMP" command.
    ///
    /// Handles jumping in place or jumping over objects.
    /// Provides appropriate responses based on ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Jumping on or over something
        guard let item = try await context.itemDirectObject() else {
            // Handle JUMP with no object - general jumping
            return ActionResult(
                context.msg.jump()
            )
        }

        return await ActionResult(
            item.response(
                object: context.msg.jumpObject,
                character: context.msg.jumpCharacter,
                enemy: context.msg.jumpEnemy
            ),
            item.setFlag(.isTouched)
        )
    }
}
