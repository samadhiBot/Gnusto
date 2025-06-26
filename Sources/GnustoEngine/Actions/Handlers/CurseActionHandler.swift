import Foundation

/// Handles the CURSE verb for swearing, cursing, or expressing frustration.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to curse or swear. Based on ZIL tradition.
public struct CurseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.damn, .directObject),
    ]

    public let verbs: [Verb] = [.curse, .swear, .shit, .fuck, .damn]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CURSE" command.
    ///
    /// This action provides humorous responses to player attempts to curse or swear.
    /// Can be used with or without a target object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        if let directObjectRef = command.directObject {
            // Cursing at something
            guard case .item(let targetItemID) = directObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.thatsNotSomethingYouCan(.curse)
                )
            }

            // Check if item exists and is accessible
            let targetItem = try await engine.item(targetItemID)
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            return ActionResult(
                engine.messenger.curseTargetResponse(
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        } else {
            // General cursing (no object)
            return ActionResult(
                engine.messenger.curseResponse()
            )
        }
    }
}
