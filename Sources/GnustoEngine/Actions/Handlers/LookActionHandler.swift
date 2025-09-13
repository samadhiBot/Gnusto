import Foundation

/// Handles the "LOOK" command and its synonyms (e.g., "L").
///
/// - When used without a direct object ("LOOK"), it describes the player's current location,
///   including its name, description, and any visible items.
/// - Other forms like "LOOK AT [ITEM]" are handled by dedicated action handlers.
public struct LookActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.look, .l]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "LOOK" command.
    ///
    /// This action handles the basic LOOK command without objects.
    /// For LOOK AT, LOOK IN, etc. with objects, those are handled by 
    /// dedicated action handlers (ExamineActionHandler, LookInsideActionHandler, etc.)
    public func process(context: ActionContext) async throws -> ActionResult {
        try await context.engine.describeCurrentLocation(
            forceFullDescription: true
        )
    }
}
