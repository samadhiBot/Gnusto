import Foundation

/// Manages the state of the game world.
public class World {
    /// All objects in the game world
    private var objects: [Object.ID: Object]

    /// The player object
    public private(set) var player: Object

    /// Current game state
    public private(set) var state: World.State

    /// Tracks IDs of rooms the player has entered.
    public internal(set) var visitedRooms: Set<Object.ID> = []

    /// The object most recently mentioned by the player
    public private(set) var lastMentionedObject: Object.ID?

    /// The event manager for scheduling events
    private let eventManager = EventManager()

    /// Creates a new game world with the specified player object
    public init(player: Object = Object.player()) {
        self.objects = [:]
        self.player = player
        self.state = .running
    }

    /// Adds one or more objects to the world.
    ///
    /// The objects must not already exist in the world.
    ///
    /// - Parameter newObjects: The new objects to add to the world.
    public func add(_ newObjects: Object...) {
        for object in newObjects {
            assert(
                objects[object.id] == nil,
                "Attempted to add object \(object.id) that already exists"
            )
            objects[object.id] = object
        }
    }

    /// Modifies an object stored in the world using a transformation closure.
    ///
    /// Handles fetching the object, applying the changes, and writing it back.
    ///
    /// - Parameters:
    ///   - id: The ID of the object to modify.
    ///   - transform: A closure that takes the current object as an `inout` parameter
    ///                and applies modifications.
    /// - Throws: An error if the object is not found or if the transform closure throws.
    public func modify(id: Object.ID, _ transform: (Object) -> Void) {
        guard let object = self.objects[id] else {
            if id == player.id {
                transform(player)
                return
            }
            assertionFailure("Attempted to modify non-existent object \(id)")
            return
        }
        transform(object)
    }
}

// MARK: - Finders

extension World {
    /// Finds an object in the world by its identifier.
    public func find(_ id: Object.ID) -> Object? {
        if let object = objects[id] {
            object
        } else if id == player.id {
            player
        } else {
            nil
        }
    }

    /// Finds all objects in a room or container.
    ///
    /// - Parameter containerID: The identifier of the room or container to search.
    /// - Returns: Any objects inside the room or container.
    public func find(in containerID: Object.ID) -> [Object] {
        objects.values.filter { object in
            object.find(LocationComponent.self)?.parentID == containerID
        }
    }

    /// Finds any objects with a matching a name or synonym.
    ///
    /// - Parameter name: A name to attempt to match.
    /// - Returns: Any objects with a matching a name or synonym.
    public func find(named name: String) -> [Object] {
        // Split the name into words
        let words = name.lowercased().components(separatedBy: .whitespaces)

        // Find all objects in the current location
        guard let playerLocation else {
            return []
        }
        let objects = contents(of: playerLocation.id)

        // Filter objects based on name, synonyms, and adjectives
        return objects.filter { object in
            if name == object.id.rawValue { return true }
            guard let desc = object.find(DescriptionComponent.self) else { return false }

            // Get the object's name, synonyms, and adjectives
            let objectNames = [desc.name] + desc.synonyms
            let objectWords = objectNames.flatMap { $0.lowercased().components(separatedBy: .whitespaces) }
            let objectAdjectives = desc.adjectives.map { $0.lowercased() }

            // If we have multiple words in the input, try to match them
            if words.count > 1 {
                // Try to match all words in any order
                let allWordsMatch = words.allSatisfy { word in
                    objectWords.contains(word) || objectAdjectives.contains(word)
                }

                if allWordsMatch {
                    return true
                }
            } else {
                // Single word match
                if objectWords.contains(words[0]) || objectAdjectives.contains(words[0]) {
                    return true
                }
            }

            return false
        }
    }

    /// Finds all objects that have the specified component type.
    ///
    /// - Parameter componentType: The target component type.
    /// - Returns: All objects with the specified component type.
    public func find<T: Component>(with componentType: T.Type) -> [Object] {
        objects.values.filter { object in
            object.has(componentType)
        }
    }

    /// Finds the object representing the location (e.g., room) of a given object.
    ///
    /// - Parameter objectID: The ID of the object whose location is needed.
    /// - Returns: The `Object` representing the location, or `nil` if the object
    ///   or its location component is not found.
    public func location(of objectID: Object.ID) -> Object? {
        guard let object = find(objectID),
              let locationComponent = object.find(LocationComponent.self),
              let parentID = locationComponent.parentID
        else {
            return nil // Object not found or has no location
        }
        return find(parentID) // Return the parent object (the location)
    }
}

// MARK: - Modifiers

extension World {
    /// Updates the last mentioned object.
    ///
    /// - Parameter objectID: The object's unique identifier.
    public func mention(_ objectID: Object.ID) {
        lastMentionedObject = objectID
    }

    /// Moves an object to a new parent.
    ///
    /// - Parameters:
    ///   - objectID: The object's unique identifier.
    ///   - parentID: The new parent's unique identifier.
    public func move(_ objectID: Object.ID, to parentID: Object.ID?) {
        modify(id: objectID) { object in
            if object.has(LocationComponent.self) {
                object.modify(LocationComponent.self) {
                    $0.parentID = parentID
                }
            } else {
                object.add(
                    LocationComponent(in: parentID)
                )
            }
        }
    }

    /// Removes an object from the world, including any child objects.
    ///
    /// - Parameter objectID: The object's unique identifier.
    public func remove(_ objectID: Object.ID) {
        for child in contents(of: objectID) {
            remove(child.id)
        }
        objects.removeValue(forKey: objectID)
    }
}

// MARK: - Attributes

extension World {
    /// Determines if a location has light
    public func isIlluminated(_ locationID: Object.ID) -> Bool {
        // Check if the room itself is lit
        if let room = find(locationID),
           let roomComponent = room.find(RoomComponent.self),
           roomComponent.isLit {
            return true
        }

        // Check for active light sources in this room
        let objectsInRoom = find(in: locationID)
        for object in objectsInRoom {
            if let lightSource = object.find(LightSourceComponent.self), lightSource.isOn {
                return true
            }
        }

        // Check if player is carrying a light source
        let inventory = find(in: player.id)
        for item in inventory {
            if let lightSource = item.find(LightSourceComponent.self), lightSource.isOn {
                return true
            }
        }

        // No light sources found
        return false
    }
}

// MARK: - Player helpers

extension World {
    /// Returns the player's current location.
    public var playerLocation: Object? {
        guard let locationID = player.find(LocationComponent.self)?.parentID else {
            return nil
        }
        return find(locationID)
    }

    /// Moves the player to the specified destination.
    ///
    /// - Parameter destinationID: The player's destination.
    /// - Returns: Any onEnter effects associated with the destination.
    @discardableResult
    public func movePlayer(to destinationID: Object.ID) -> [Effect] {
        guard
            let destination = find(destinationID),
            destination.has(RoomComponent.self) || destination.has(ContainerComponent.self)
        else {
            assertionFailure("Attempted to move player to invalid destination: `\(destinationID)`")
            return []
        }

        // Mark the destination room as visited
        if destination.has(RoomComponent.self) {
            visitedRooms.insert(destinationID)
        }

        // Update player's location component
        move(player.id, to: destinationID)

        // Return any onEnter effects from the destination room
        if let roomHooks = destination.find(RoomHooksComponent.self),
           let onEnter = roomHooks.onEnter {
            return onEnter(self)
        } else {
            return []
        }
    }

    /// Modifies the player using a transformation closure.
    ///
    /// - Parameter transform: A closure that takes the player object as an `inout` parameter
    ///                        and applies modifications.
    public func modifyPlayer(_ transform: (inout Object) -> Void) {
        var modifiedPlayer = self.player
        transform(&modifiedPlayer)
        self.player = modifiedPlayer
    }
}

// MARK: - State helpers

extension World {
    /// Updates the game state.
    public func updateState(to newState: World.State) {
        state = newState
    }
}

// MARK: - Global State

//extension World {
//    /// Gets the global state component, creating it if it doesn't exist.
//    ///
//    /// - Returns: The global state component.
//    public func globalState() -> GlobalStateComponent {
//        guard let worldObject = find("world") else {
//            let worldObject = Object(id: "world", GlobalStateComponent())
//            add(worldObject)
//            return worldObject.find(GlobalStateComponent.self)!
//        }
//        guard let state = worldObject.find(GlobalStateComponent.self) else {
//            assertionFailure("World object expected to have global state component")
//            return GlobalStateComponent()
//        }
//        return state
//    }
//
//    /// Sets a global state value.
//    /// - Parameters:
//    ///   - value: The value to store.
//    ///   - key: The key to associate with the value.
//    public func setGlobalState<T: Sendable>(_ value: T, for key: String) {
//        guard let worldObject = find("world") else {
//            var stateComponent = GlobalStateComponent()
//            stateComponent.set(value, for: key)
//            let worldObject = Object(id: "world", stateComponent)
//            add(worldObject)
//            return
//        }
//
//        if var state = worldObject.find(GlobalStateComponent.self) {
//            state.set(value, for: key)
//            modify(id: worldObject.id) { object in
//                object.modify(GlobalStateComponent.self) { <#inout Component#> in
//                    <#code#>
//                }
//            }
////            worldobject.add(state)
//        } else {
//            var stateComponent = GlobalStateComponent()
//            stateComponent.set(value, for: key)
//            worldobject.add(stateComponent)
//        }
//    }
//
//    /// Gets a global state value.
//    /// - Parameter key: The key to retrieve.
//    /// - Returns: The value associated with the key, or nil if not found or type mismatch.
//    public func getGlobalState<T>(_ key: String) -> T? {
//        return globalState().get(key)
//    }
//
//    /// Checks if a global state value exists.
//    /// - Parameter key: The key to check.
//    /// - Returns: True if a value exists for the key.
//    public func hasGlobalState(_ key: String) -> Bool {
//        return globalState().has(key)
//    }
//
//    /// Removes a global state value.
//    /// - Parameter key: The key to remove.
//    public func removeGlobalState(_ key: String) {
//        guard
//            let worldObject = find("world"),
//            var state = worldObject.find(GlobalStateComponent.self)
//        else {
//            assertionFailure("No world object found")
//            return
//        }
//        state.remove(key)
//        worldobject.add(state)
//    }
//}

// MARK: - Event Management

extension World {
    /// Schedule a new event to run after the specified number of turns
    /// - Parameters:
    ///   - id: The event's unique identifier
    ///   - delay: The number of turns before the event executes
    ///   - isRepeating: Whether this event repeats indefinitely
    ///   - data: Additional data associated with this event
    /// - Returns: True if the event was scheduled, false if an event with this ID already exists
    @discardableResult
    public func scheduleEvent(
        _ id: Event.ID,
        delay: Int,
        isRepeating: Bool = false,
        data: [String: String] = [:]
    ) -> Bool {
        eventManager.scheduleEvent(id: id, delay: delay, isRepeating: isRepeating, data: data)
    }

    /// Cancel a scheduled event
    /// - Parameter id: The ID of the event to cancel
    /// - Returns: True if the event was found and cancelled, false otherwise
    @discardableResult
    public func cancelEvent(_ id: Event.ID) -> Bool {
        eventManager.cancelEvent(id: id)
    }

    /// Check if an event is currently scheduled
    /// - Parameter id: The ID of the event to check
    /// - Returns: True if the event is scheduled, false otherwise
    public func isEventScheduled(_ id: Event.ID) -> Bool {
        eventManager.isEventScheduled(id: id)
    }

    /// Get a scheduled event by ID
    /// - Parameter id: The ID of the event to get
    /// - Returns: The event if found, nil otherwise
    public func getEvent(_ id: Event.ID) -> Event? {
        eventManager.getEvent(id: id)
    }

    /// Process events for the current turn, executing any that are due
    /// - Returns: The IDs of events that should be executed this turn
    public func processEvents() -> [Event.ID] {
        eventManager.processEvents()
    }

    /// Get all currently scheduled events
    public var scheduledEvents: [Event] {
        eventManager.scheduledEvents
    }
}

// MARK: - Room Connections

extension World {
    /// Connect two rooms with a direct exit.
    ///
    /// - Parameters:
    ///   - originID: The origin room ID.
    ///   - direction: The direction of the exit.
    ///   - destinationID: The destination room ID.
    ///   - bidirectional: Whether to create a return exit.
    public func connect(
        from originID: Object.ID,
        direction: Direction,
        to destinationID: Object.ID,
        bidirectional: Bool = true
    ) {
        modify(id: originID) { originRoom in
            originRoom.modify(RoomComponent.self) { component in
                component.addExit(direction: direction, to: destinationID)
            }
        }
        if bidirectional {
            modify(id: destinationID) { destinationRoom in
                destinationRoom.modify(RoomComponent.self) { component in
                    component.addExit(direction: direction.opposite, to: originID)
                }
            }
        }
    }

    /// Connect a room with a conditional exit.
    ///
    /// - Parameters:
    ///   - originID: The origin room ID.
    ///   - direction: The direction of the exit.
    ///   - conditionalExit: The conditional exit configuration.
    /// - Returns: The builder for chaining.
    public func connectConditional(
        from originID: Object.ID,
        direction: Direction,
        conditionalExit: ConditionalExit
    ) {
        modify(id: originID) { originRoom in
            originRoom.modify(RoomComponent.self) { component in
                component.addExit(direction: direction, conditional: conditionalExit)
            }
        }
    }
}

// MARK: - Room & Container Contents

extension World {
    /// Returns all objects located directly within the specified parent object.
    ///
    /// This is useful for finding the contents of containers or rooms.
    ///
    /// - Parameter containerID: The ID of a room or container.
    /// - Returns: An array of `Object` instances located directly within the parent.
    public func contents(of containerID: Object.ID) -> [Object] {
        objects.values.filter { object in
            object.isDirectlyInside(containerID)
        }
    }
}
