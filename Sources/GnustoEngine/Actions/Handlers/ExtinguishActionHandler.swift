import Foundation

/// Handles the "EXTINGUISH" command for lit flammable items like torches, candles, and fires.
///
/// This handler specifically deals with extinguishing lit flammable objects,
/// as opposed to mechanical devices that can be turned off. It validates that
/// the target item is flammable and currently lit before extinguishing it.
public struct ExtinguishActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.blow, .out, .directObject),
        .match(.verb, .directObject),
    ]

    public let synonyms: [Verb] = [.extinguish, .douse]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "EXTINGUISH" command for lit flammable items.
    ///
    /// This action validates that the target item is flammable and currently lit,
    /// then extinguishes it if possible. Handles special behavior for items
    /// that were providing light when extinguished.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object and ensure it's an item
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if it's a light source that's currently lit
        if await item.hasFlags(all: .isLightSource, .isOn) {
            return await ActionResult(
                context.msg.extinguishSuccess(
                    context.command,
                    item: item.withDefiniteArticle
                ),
                item.clearFlag(.isBurning),
                item.clearFlag(.isOn),
                item.setFlag(.isTouched)
            )
        }

        // Check if it's currently lit
        guard await item.hasFlag(.isBurning) else {
            throw await ActionResponse.feedback(
                context.msg.extinguishFail(
                    context.command,
                    item: item.withDefiniteArticle
                )
            )
        }

        return await ActionResult(
            context.msg.extinguishSuccess(
                context.command,
                item: item.withDefiniteArticle
            ),
            item.setFlag(.isTouched),
            item.clearFlag(.isBurning)
        )
    }
}
