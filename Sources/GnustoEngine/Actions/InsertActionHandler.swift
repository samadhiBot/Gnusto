import Foundation

/// Handles the "INSERT [item] INTO/IN [container]" action.
@MainActor
struct InsertActionHandler: EnhancedActionHandler {
    func validate(
        command: Command,
        engine: GameEngine
    ) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let itemToInsertID = command.directObject else {
            throw ActionError.prerequisiteNotMet("Insert what?")
        }
        guard let containerID = command.indirectObject else {
            // Fetch name for better error message if possible
            let itemName = engine.item(with: itemToInsertID)?.name ?? "item"
            throw ActionError.prerequisiteNotMet("Where do you want to insert the \(itemName)?")
        }

        // 2. Get Item Snapshots
        guard let itemToInsert = engine.item(with: itemToInsertID) else {
            throw ActionError.itemNotAccessible(itemToInsertID)
        }
        guard let containerItem = engine.item(with: containerID) else {
            throw ActionError.itemNotAccessible(containerID)
        }

        // 3. Perform Basic Checks
        guard itemToInsert.parent == .player else {
            throw ActionError.itemNotHeld(itemToInsertID)
        }
        let reachableItems = engine.scopeResolver.itemsReachableByPlayer()
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
            guard let parentItem = engine.item(with: parentItemID) else { break }
            currentParent = parentItem.parent
        }

        // 4. Target Checks (Specific to INSERT)
        guard containerItem.hasProperty(.container) else {
            throw ActionError.targetIsNotAContainer(containerID)
        }
        guard containerItem.hasProperty(.open) else {
            throw ActionError.containerIsClosed(containerID)
        }

        // Capacity Check (New)
        // Check if container has limited capacity (capacity >= 0)
        if containerItem.capacity >= 0 {
            // Fix: Calculate load manually
            let itemsInside = engine.items(withParent: .item(containerID))
            let currentLoad = itemsInside.reduce(0) { $0 + $1.size }
            let itemSize = itemToInsert.size
            if currentLoad + itemSize > containerItem.capacity {
                throw ActionError.containerIsFull(containerID)
            }
        }
    }

    func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {
        // IDs guaranteed non-nil by validate
        let itemToInsertID = command.directObject!
        let containerID = command.indirectObject!

        // Get snapshots (existence guaranteed by validate)
        guard let itemToInsertSnapshot = engine.item(with: itemToInsertID),
              let containerSnapshot = engine.item(with: containerID) else
        {
            throw ActionError.internalEngineError("Item snapshot disappeared between validate and process for INSERT.")
        }

        // --- Insert Successful: Calculate State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Update item parent
        let oldParent = itemToInsertSnapshot.parent // Should be .player
        let newParent: ParentEntity = .item(containerID)
        stateChanges.append(StateChange(
            entityId: .item(itemToInsertID),
            propertyKey: .itemParent,
            oldValue: .parentEntity(oldParent),
            newValue: .parentEntity(newParent)
        ))

        // Change 2: Mark item touched
        let oldItemProps = itemToInsertSnapshot.properties
        if !oldItemProps.contains(.touched) {
            var newItemProps = oldItemProps
            newItemProps.insert(.touched)
            stateChanges.append(StateChange(
                entityId: .item(itemToInsertID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldItemProps),
                newValue: .itemProperties(newItemProps)
            ))
        }

        // Change 3: Mark container touched
        let oldContainerProps = containerSnapshot.properties
        if !oldContainerProps.contains(.touched) {
            var newContainerProps = oldContainerProps
            newContainerProps.insert(.touched)
            stateChanges.append(StateChange(
                entityId: .item(containerID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldContainerProps),
                newValue: .itemProperties(newContainerProps)
            ))
        }

        // Change 4: Update pronoun "it"
        stateChanges.append(StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([itemToInsertID])
        ))

        // --- Prepare Result ---
        let message = "You put the \(itemToInsertSnapshot.name) in the \(containerSnapshot.name)."
        return ActionResult(
            success: true,
            message: message,
            stateChanges: stateChanges
        )
    }
}
