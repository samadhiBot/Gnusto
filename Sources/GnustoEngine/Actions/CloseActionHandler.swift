import Foundation

/// Handles the "CLOSE" context.command.
public struct CloseActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler

    public func validate(context: ActionContext) async throws {
        // 1. Ensure we have a direct object
        guard let targetItemID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Close what?")
        }

        // 2. Check if item exists
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Standard approach: If parser resolved it, but it's gone, treat as inaccessible.
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 3. Check reachability using ScopeResolver
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(targetItemID) else {
            throw ActionError.itemNotAccessible(targetItemID)
        }

        // 4. Check if item is closable (using .openable for symmetry)
        guard targetItem.hasFlag(.isOpenable) else {
            throw ActionError.itemNotClosable(targetItemID)
        }

        // 5. Check if already closed (using dynamic property)
        let isOpen: Bool = try await context.engine.fetch(targetItemID, .isOpen)
        guard isOpen else {
            // Don't throw, let process handle the specific message "That's already closed."
            return
        }

        // Note: Closing doesn't usually depend on locked status.
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObject else {
            // Should be caught by validate, but defensive check.
            throw ActionError.internalEngineError("Close context.command reached process without direct object.")
        }
        guard let targetItem = await context.engine.item(targetItemID) else {
            // Should be caught by validate.
            throw ActionError.internalEngineError("Close context.command target item disappeared between validate and process.")
        }

        // Handle "already closed" case detected (but not thrown) in validate
        let isOpen: Bool = try await context.engine.fetch(targetItemID, .isOpen)
        if !isOpen {
            return ActionResult(
                success: false,
                message: "\(targetItem.withDefiniteArticle.capitalizedFirst) is already closed."
            )
        }

        // --- Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Set dynamic property isOpen to false
        // This call applies the state change internally.
        // NOTE: The state change for `isOpen` is generated *inside* setDynamicItemValue.
        // We only need to manually create the change for `.isTouched` here.
        try await context.engine.setDynamicItemValue(
            itemID: targetItemID,
            key: .isOpen,
            newValue: false
        )

        // Change 2: Set `.isTouched` flag if not already set
        if targetItem.attributes[.isTouched] != true {
            let touchedChange = StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false, // Current value (or default false)
                newValue: true,
            )
            stateChanges.append(touchedChange)
        }

        // Change 3: Pronoun ("it")
        let oldPronounValue = await context.engine.getPronounReference(pronoun: "it")
        let pronounChange = StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: oldPronounValue.map { .itemIDSet($0) },
            newValue: .itemIDSet([targetItemID])
        )
        stateChanges.append(pronounChange)

        // --- Prepare Result ---
        return ActionResult(
            success: true,
            message: "Closed.", // Standard Zork message
            stateChanges: stateChanges, // Only includes touched change if needed
            sideEffects: []
        )
    }

    // Rely on default postProcess to print the message.
}

// TODO: Add/verify ActionError cases: .itemNotClosable, .itemAlreadyClosed
