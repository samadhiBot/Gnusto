import Foundation

/// Handles the "INSERT <direct object> INTO/IN <indirect object>" command, allowing the player
/// to place an item they are holding into an open container item.
public struct InsertActionHandler: ActionHandler {
    /// Validates the "INSERT ... INTO/IN" command.
    ///
    /// This method ensures that:
    /// 1. Both a direct object (the item to insert) and an indirect object (the container)
    ///    are specified and are valid items.
    /// 2. The player is currently holding the direct object item.
    /// 3. The direct object item is not scenery (fixed, unmovable items).
    /// 4. The player can reach the indirect object (container) item.
    /// 5. The direct object is not the same as the indirect object (cannot insert an item into itself).
    /// 6. The indirect object (container) is not currently inside the direct object (prevents
    ///    circular placement).
    /// 7. The indirect object (container) has the `.isContainer` flag set.
    /// 8. The indirect object (container) is currently open (has the `.isOpen` dynamic property set to true).
    /// 9. The direct object item can fit into the container, based on the item's `size` and the
    ///    container's `capacity` and current load (if capacity is limited, i.e., >= 0).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing objects, wrong item types, self-insertion, circular placement),
    ///           `itemNotHeld` (if item to insert is not held),
    ///           `targetIsNotAContainer` (if direct object is scenery or indirect object is not a container),
    ///           `itemNotAccessible` (if container cannot be reached),
    ///           `containerIsClosed` (if container is not open),
    ///           `itemTooLargeForContainer` (if item won't fit).
    ///           Can also throw errors from `context.engine` calls (e.g., `item()`, `fetch()`).
    public func validate(context: ActionContext) async throws {
        // 1. Validate Direct and Indirect Objects
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Insert what?")
        }
        guard case .item(let itemToInsertID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only insert items.")
        }

        guard let indirectObjectRef = context.command.indirectObject else {
            // Fetch item name for a more informative message if indirect object is missing.
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

    /// Processes the "INSERT ... INTO/IN" command.
    ///
    /// Assuming validation has passed, this action performs the following:
    /// 1. Retrieves the item to be inserted and the container item.
    /// 2. Moves the item to be inserted so its parent becomes the container item.
    /// 3. Ensures the `.isTouched` flag is set on both the item being inserted and the container.
    /// 4. Updates pronouns to refer to the item that was inserted.
    /// 5. Returns an `ActionResult` with a confirmation message (e.g., "You put the jewel in the box.")
    ///    and the state changes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if direct or indirect objects are not items
    ///           (this should be caught by `validate`), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
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
