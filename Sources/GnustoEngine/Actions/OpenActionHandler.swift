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

        // 4. Check if locked
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

        // Check if already open using dynamic property
        let isOpen = await context.engine.getDynamicItemValue(
            itemID: targetItemID,
            key: .isOpen
        )?.toBool ?? false
        guard !isOpen else {
            throw ActionError.itemAlreadyOpen(targetItemID)
        }

        // Set the dynamic value for 'isOpen' to true
        // This function call applies the state change internally but returns Void.
        try await context.engine.setDynamicItemValue(
            itemID: targetItemID,
            key: .isOpen,
            newValue: .bool(true)
        )

        // Update the 'touched' property - This remains a static property for now.
        // TODO: Consider if 'touched' should also be dynamic or handled differently.
        var touchedProperties = targetItem.properties
        let alreadyTouched = touchedProperties.contains(.touched)
        var touchedStateChange: StateChange?
        if !alreadyTouched {
            touchedProperties.insert(.touched)
            touchedStateChange = StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(targetItem.properties), // Original properties before touch
                newValue: .itemPropertySet(touchedProperties)     // Properties with .touched added
            )
        }

        // Prepare the result
        return ActionResult(
            success: true,
            message: "You open the \(targetItem.name).",
            // Only include touched change if it happened. The open change is applied by setDynamicItemValue.
            stateChanges: touchedStateChange.map { [$0] } ?? []
        )
    }

    // Rely on default postProcess to print the message.
    // Engine's execute method handles applying the stateChanges.
}

// TODO: Add/verify ActionError cases: .itemNotOpenable, .itemAlreadyOpen, .itemIsLocked
