import Foundation

/// Handles the "INSERT [item] INTO/IN [container]" action.
struct InsertActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let itemToInsertID = context.command.directObject else {
            throw ActionError.prerequisiteNotMet("Insert what?")
        }
        guard let containerID = context.command.indirectObject else {
            // Fetch name for better error message if possible
            let itemName = await context.engine.item(itemToInsertID)?.name ?? "item"
            throw ActionError.prerequisiteNotMet("Where do you want to insert the \(itemName)?")
        }

        // 2. Get Item s
        guard let itemToInsert = await context.engine.item(itemToInsertID) else {
            throw ActionError.itemNotAccessible(itemToInsertID)
        }
        guard let containerItem = await context.engine.item(containerID) else {
            throw ActionError.itemNotAccessible(containerID)
        }

        // 3. Perform Basic Checks
        guard itemToInsert.parent == .player else {
            throw ActionError.itemNotHeld(itemToInsertID)
        }
        let reachableItems = await context.engine.scopeResolver.itemsReachableByPlayer()
        guard reachableItems.contains(containerID) else {
             throw ActionError.itemNotAccessible(containerID)
        }

        // Prevent putting item inside/onto itself
        if itemToInsertID == containerID {
             throw ActionError.prerequisiteNotMet("You can't put something in itself.")
        }
        // Recursive check: is the target container inside the item we are inserting?
        var currentParent = containerItem.parent
        while case .item(let parentItemID) = currentParent {
            if parentItemID == itemToInsertID {
                throw ActionError.prerequisiteNotMet("You can't put the \(containerItem.name) inside the \(itemToInsert.name) like that.")
            }
            guard let parentItem = await context.engine.item(parentItemID) else { break }
            currentParent = parentItem.parent
        }

        // 4. Target Checks (Specific to INSERT)
        guard containerItem.hasFlag(.isContainer) else {
            throw ActionError.targetIsNotAContainer(containerID)
        }
        // Check dynamic property for open state
        guard try await context.engine.fetch(containerID, .isOpen) else {
            throw ActionError.containerIsClosed(containerID)
        }

        // Capacity Check (New)
        // Check if container has limited capacity (capacity >= 0)
        if containerItem.capacity >= 0 {
            // Fix: Calculate load manually
            let itemsInside = await context.engine.items(in: .item(containerID))
            let currentLoad = itemsInside.reduce(0) { $0 + $1.size }
            let itemSize = itemToInsert.size
            if currentLoad + itemSize > containerItem.capacity {
                throw ActionError.containerIsFull(containerID)
            }
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // IDs guaranteed non-nil by validate
        let itemToInsertID = context.command.directObject!
        let containerID = context.command.indirectObject!

        // Get snapshots (existence guaranteed by validate)
        guard
            let itemToInsert = await context.engine.item(itemToInsertID),
            let container = await context.engine.item(containerID)
        else {
            throw ActionError.internalEngineError(
                "Item snapshot disappeared between validate and process for INSERT."
            )
        }

        // --- Insert Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Update item parent
        let oldParent = itemToInsert.parent // Should be .player
        let newParent: ParentEntity = .item(containerID)
        stateChanges.append(StateChange(
            entityID: .item(itemToInsertID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(oldParent),
            newValue: .parentEntity(newParent)
        ))

        // Change 2: Mark item touched
        if let touchedStateChange = await context.engine.flag(itemToInsert, with: .isTouched) {
            stateChanges.append(touchedStateChange)
        }

        // Change 2: Mark container touched
        if let touchedStateChange = await context.engine.flag(container, with: .isTouched) {
            stateChanges.append(touchedStateChange)
        }

        // Change 4: Update pronoun
        if let pronounStateChange = await context.engine.pronounStateChange(for: itemToInsert) {
            stateChanges.append(pronounStateChange)
        }

        // --- Prepare Result ---
        let message = "You put the \(itemToInsert.name) in the \(container.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
