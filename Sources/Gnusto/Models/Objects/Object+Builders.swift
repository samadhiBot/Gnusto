import Foundation

/// A set of specialized object builders.
extension Object {
    /// Create a container object.
    ///
    /// - Parameters:
    ///   - id: The container ID.
    ///   - name: The container name.
    ///   - description: The container description.
    ///   - location: The starting location.
    ///   - isOpen: Whether the container starts open.
    ///   - isTransparent: Whether the container is transparent.
    ///   - capacity: The container's capacity.
    ///   - flags: Any flags set on the object.
    ///   - synonyms: Any synonyms for the container.
    /// - Returns: The created container object.
    public static func container<each T: Component>(
        id: Object.ID,
        name: String,
        description: String,
        flags: Flag...,
        synonyms: String...,
        adjectives: String...,
        location: Object.ID? = nil,
        isOpen: Bool = false,
        isTransparent: Bool = false,
        capacity: Int? = nil,
        _ components: repeat each T
    ) -> Object {
        var container = Object(
            id: id,
            ContainerComponent(
                isOpen: isOpen,
                isTransparent: isTransparent,
                capacity: capacity
            ),
            DescriptionComponent(
                name: name,
                description: description,
                synonyms: synonyms,
                adjectives: adjectives
            ),

            LocationComponent(
                in: location
            ),
            ObjectComponent(
                flags: Set(flags).union([.container, .openable])
            )
        )

        let stored = (repeat each components)
        for component in repeat each stored {
            container.add(component)
        }

        return container
    }

    /// Create a game item.
    ///
    /// - Parameters:
    ///   - id: The item ID.
    ///   - name: The item name.
    ///   - description: The item description.
    ///   - location: The starting location.
    ///   - flags: Any flags set on the item.
    ///   - synonyms: Any synonyms for the item.
    ///   - adjectives: Any adjectives that can be used to describe the item.
    /// - Returns: The created item with object component.
    public static func item<each T: Component>(
        id: Object.ID,
        name: String,
        description: String,
        flags: Flag...,
        synonyms: String...,
        adjectives: String...,
        location: Object.ID? = nil,
        _ components: repeat each T
    ) -> Object {
        var object = Object(
            id: id,
            DescriptionComponent(
                name: name,
                description: description,
                synonyms: synonyms,
                adjectives: adjectives
            ),
            LocationComponent(
                in: location
            ),
            ObjectComponent(
                flags: Set(flags)
            )
        )

        let stored = (repeat each components)
        for component in repeat each stored {
            object.add(component)
        }

        return object
    }

    /// Create a player object.
    ///
    /// - Parameters:
    ///   - id: The player ID.
    ///   - name: The player name.
    ///   - description: The player description.
    ///   - location: The starting location.
    /// - Returns: The created player object.
    public static func player(
        id: Object.ID = "player",
        name: String = "You",
        description: String = "As good-looking as ever.",
        location: Object.ID? = nil
    ) -> Object {
        Object(
            id: id,
            DescriptionComponent(
                name: name,
                description: description
            ),
            LocationComponent(
                in: location
            ),
            PlayerComponent()
        )
    }

    /// Creates a room object.
    ///
    /// - Parameters:
    ///   - id: The room ID.
    ///   - name: The room name.
    ///   - description: The room description.
    ///   - isLit: Whether the room is lit.
    ///   - darkDescription: An optional description when the room is dark.
    ///   - exits: Any exits out of the room.
    /// - Returns: The created room object.
    public static func room<each T: Component>(
        id: Object.ID,
        name: String,
        description: String,
        isLit: Bool = true,
        darkDescription: String? = nil,
        flags: Flag...,
        synonyms: String...,
        adjectives: String...,
        exits: [Direction: Exit] = [:],
        _ components: repeat each T
    ) -> Object {
        var room = Object(
            id: id,
            DescriptionComponent(
                name: name,
                description: description,
                synonyms: synonyms,
                adjectives: adjectives
            ),
            ObjectComponent(
                flags: Set(flags)
            ),
            RoomComponent(
                isLit: isLit,
                darkDescription: darkDescription,
                exits: exits
            )
        )

        let stored = (repeat each components)
        for component in repeat each stored {
            room.add(component)
        }

        return room
    }
}
