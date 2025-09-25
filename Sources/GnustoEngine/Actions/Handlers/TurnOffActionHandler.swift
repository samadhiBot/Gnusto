import Foundation

/// Handles the "TURN OFF" command for devices that can be switched on and off.
///
/// This handler specifically deals with mechanical devices that have on/off states,
/// as opposed to flammable objects that can be extinguished. It validates that
/// the target item is a device and is currently on before turning it off.
public struct TurnOffActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .off, .directObject)
    ]

    public let synonyms: [Verb] = [.switch, .turn]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN OFF" command for devices.
    ///
    /// This action validates prerequisites and deactivates the specified device.
    /// Only handles devices that can be turned on/off (items with the .isDevice flag).
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (with automatic reachability checking)
        guard let targetItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if the item is a device
        guard await targetItem.hasFlag(.isDevice) else {
            throw ActionResponse.feedback(
                context.msg.cannotTurnOff()
            )
        }

        // Check if the item is currently on
        guard await targetItem.hasFlag(.isOn) else {
            throw ActionResponse.feedback(
                context.msg.alreadyOff()
            )
        }

        return await ActionResult(
            context.msg.lightIsNowOff(targetItem.withDefiniteArticle),
            targetItem.setFlag(.isTouched),
            targetItem.clearFlag(.isOn)
        )
    }
}
