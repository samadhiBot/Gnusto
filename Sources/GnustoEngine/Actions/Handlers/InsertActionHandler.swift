import Foundation

/// Handles the "INSERT [item] INTO/IN [container]" action.
struct InsertActionHandler: ActionHandler {
    func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Insert what?")
        }
        guard case .item(let itemToInsertID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only insert items.")
        }

        guard let indirectObjectRef = context.command.indirectObject else {
            let itemName = (try? await context.engine.item(itemToInsertID))?.name ?? itemToInsertID.rawValue
            throw ActionResponse.prerequisiteNotMet("Where do you want to insert the \(itemName)?")
        }
        guard case .item(let containerID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only insert items into other items (that are containers).")
        }

        // 2. Get Items (existence validated by directObjectRef/indirectObjectRef checks if entities exist)
        let itemToInsert = try await context.engine.item(itemToInsertID)
        let containerItem = try await context.engine.item(containerID)

        // 3. Perform Basic Checks
        guard itemToInsert.parent == .player else {
            throw ActionResponse.itemNotHeld(itemToInsertID)
        }

        // If the item being inserted is fixed scenery, Zork replies as if it is not a container.
        if itemToInsert.hasFlag(.isScenery) {
            throw ActionResponse.targetIsNotAContainer(itemToInsertID)
        }

        guard await context.engine.playerCanReach(containerID) else {
             throw ActionResponse.itemNotAccessible(containerID)
        }

        // Prevent putting item inside/onto itself
        if itemToInsertID == containerID {
             throw ActionResponse.prerequisiteNotMet("You can't put something inside itself.")
        }

        // Recursive check: is the target container inside the item we are inserting?
        var currentParent = containerItem.parent
        while case .item(let parentItemID) = currentParent {
            if parentItemID == itemToInsertID {
                throw ActionResponse.prerequisiteNotMet(
                    "You can't put the \(itemToInsert.name) in the \(containerItem.name), because the \(containerItem.name) is inside the \(itemToInsert.name)!"
                )
            }
            let parentItem = try await context.engine.item(parentItemID)
            currentParent = parentItem.parent
        }

        // 4. Target Checks (Specific to INSERT)
        guard containerItem.hasFlag(.isContainer) else {
            throw ActionResponse.targetIsNotAContainer(containerID)
        }
        // Check dynamic property for open state
        guard try await context.engine.fetch(containerID, .isOpen) else {
            throw ActionResponse.containerIsClosed(containerID)
        }

        // Capacity Check (New)
        // Check if container has limited capacity (capacity >= 0)
        if containerItem.capacity >= 0 {
            // Fix: Calculate load manually
            let itemsInside = await context.engine.items(in: .item(containerID))
            let currentLoad = itemsInside.reduce(0) { $0 + $1.size }
            let itemSize = itemToInsert.size
            if currentLoad + itemSize > containerItem.capacity {
                throw ActionResponse.itemTooLargeForContainer(
                    item: itemToInsertID,
                    container: containerID
                )
            }
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        // Direct and Indirect objects are guaranteed to be items by validate.
        guard let directObjectRef = context.command.directObject,
              case .item(let itemToInsertID) = directObjectRef else {
            // Should not happen if validate passed.
            throw ActionResponse.internalEngineError("Insert: Direct object not an item in process.")
        }
        guard let indirectObjectRef = context.command.indirectObject,
              case .item(let containerID) = indirectObjectRef else {
            // Should not happen if validate passed.
            throw ActionResponse.internalEngineError("Insert: Indirect object not an item in process.")
        }

        // Get snapshots (existence should be guaranteed by validate)
        let itemToInsert = try await context.engine.item(itemToInsertID)
        let container = try await context.engine.item(containerID)

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
        if let update = await context.engine.setFlag(.isTouched, on: itemToInsert) {
            stateChanges.append(update)
        }

        // Change 2: Mark container touched
        if let update = await context.engine.setFlag(.isTouched, on: container) {
            stateChanges.append(update)
        }

        // Change 4: Update pronoun
        if let update = await context.engine.updatePronouns(to: itemToInsert) {
            stateChanges.append(update)
        }

        // --- Prepare Result ---
        return ActionResult(
            message: "You put the \(itemToInsert.name) in the \(container.name).",
            stateChanges: stateChanges
        )
    }
}
