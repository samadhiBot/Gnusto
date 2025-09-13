import Foundation

/// Handles the CRY verb for weeping, sobbing, or expressing sadness.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to cry or weep. Based on ZIL tradition.
public struct CryActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb)
    ]

    public let synonyms: [Verb] = [.cry, .weep, .sob]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CRY" command.
    ///
    /// This action provides humorous responses to player attempts to cry or weep.
    /// A classic atmospheric command from ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        ActionResult(
            context.msg.cryResponse()
        )
    }
}
