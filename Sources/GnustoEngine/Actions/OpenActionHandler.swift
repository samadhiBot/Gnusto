import Foundation

/// Handles the "OPEN" context.command.
public struct OpenActionHandler: EnhancedActionHandler {

    public init() {}

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Open what?")
        }

        // 2. Check if item exists and is accessible using ScopeResolver
        guard let targetItem = await context.engine.item(with: targetItemID) else {
            // If snapshot is nil, it implies item doesn't exist in current state.
            // ScopeResolver checks typically operate on existing items.
            // Let's use the standard not accessible error.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // Use ScopeResolver to determine reachability
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check if item is openable
        guard targetItem.hasProperty(.openable) else {
            throw ActionError.itemNotOpenable(targetItemID)
        }

        // 4. Check if already open
        guard !targetItem.hasProperty(.open) else {
            throw ActionError.itemAlreadyOpen(targetItemID)
        }

        // 5. Check if locked
        if targetItem.hasProperty(.locked) {
            throw ActionError.itemIsLocked(targetItemID)
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            // Should be caught by validate, but defensive check.
            throw ActionError.internalEngineError("Open context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(with: targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Open context.command target item disappeared between validate and process.")
        }

        // Calculate the new properties
        var newProperties = targetItem.properties
        newProperties.insert(.open)
        newProperties.insert(.touched)

        // Create the state change
        let stateChange = StateChange(
            entityId: .item(targetItemID),
            propertyKey: .itemProperties,
            oldValue: .itemPropertySet(targetItem.properties), // Record old state
            newValue: .itemPropertySet(newProperties)
        )

        // Prepare the result
        return ActionResult(
            success: true,
            message: "You open the \(targetItem.name).",
            stateChanges: [stateChange],
            sideEffects: []
        )
    }

    // Rely on default postProcess to print the message.
    // Engine's execute method handles applying the stateChanges.
}

// TODO: Add/verify ActionError cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
