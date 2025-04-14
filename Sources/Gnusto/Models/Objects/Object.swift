import Foundation

/// Represents an object, the basic unit in the game world.
public class Object {
    /// The unique identifier for this object.
    public let id: Object.ID

    /// The name of the object.
    public let name: String

    /// A full description of the object.
    public let description: String?

    /// Alternative names that can be used to refer to this object.
    public let synonyms: [String]

    /// Adjectives that can be used to describe this object.
    public let adjectives: [String]

    /// Flags that define this object's properties
    public var flags: Set<Flag>

    /// The identifier of the parent object (room or container) that contains this object.
    public var parentID: Object.ID?

    public init(
        id: Object.ID,
        name: String? = nil,
        description: String? = nil,
        synonyms: [String] = [],
        adjectives: [String] = [],
        flags: Set<Flag> = [],
        parentID: Object.ID? = nil
    ) {
        self.id = id
        self.name = name ?? id.rawValue
        self.description = description
        self.synonyms = synonyms
        self.adjectives = adjectives
        self.flags = flags
        self.parentID = parentID
    }
}

//    /// The components attached to this object
//    private var components: [ComponentType: any Component]
//
//    /// Creates a new object.
//    ///
//    /// This initializer is for internal use.
//    ///
//    /// - Parameters:
//    ///   - id: The object ID.
//    ///   - components: Any components attached to the object.
//    init<each T: Component>(
//        id: Object.ID,
//        _ components: repeat each T
//    ) {
//        self.id = id
//        self.components = [:]
//
//        let stored = (repeat each components)
//        for component in repeat each stored {
//            add(component)
//        }
//    }
//
//    /// The name of the object from its DescriptionComponent, if one exists.
//    public var name: String? {
//        find(DescriptionComponent.self)?.name
//    }
//}

//// MARK: - Component helpers
//
//extension Object {
//    /// Adds one or more components to the object.
//    ///
//    /// The component must not already exist in the object.
//    ///
//    /// - Parameter newComponents: The new components to add to the object.
//    public func add<each T: Component>(_ newComponents: repeat each T) {
//        let stored = (repeat each newComponents)
//        for component in repeat each stored {
//            let typeKey = Swift.type(of: component).type
//            assert(
//                components[typeKey] == nil,
//                "Attempting to add `\(typeKey)` component that already exists"
//            )
//            components[typeKey] = component
//        }
//    }
//
//    /// Finds a component of the specified type.
//    ///
//    /// - Parameter type: The component type.
//    /// - Returns: The component matching that type.
//    public func find<T: Component>(_ type: T.Type) -> T? {
//        components[T.type] as? T
//    }
//
//    /// Whether this object has a component of the specified type.
//    public func has<T: Component>(_ type: T.Type) -> Bool {
//        components[T.type] != nil
//    }
//
//    /// Modifies the component of the specified type.
//    ///
//    /// The component must already exist on the object.
//    ///
//    /// - Parameters:
//    ///   - type: The component type.
//    ///   - transform: A closure that takes the current component as an `inout` parameter
//    ///                and applies modifications.
//    /// - Note: Even though Object is a class, components (like LightSourceComponent) might still be structs,
//    ///         so the `inout` transform and write-back pattern within this method is still necessary
//    ///         for modifying struct components.
//    public func modify<T: Component>(_ type: T.Type, transform: (inout T) -> Void) {
//        guard var component = components[T.type] as? T else {
//            assertionFailure("Component \(String(describing: type)) not found for \(id).")
//            return
//        }
//        transform(&component)
//        components[T.type] = component
//    }
//
//    /// Removes a component of the specified type from the object.
//    ///
//    /// - Parameter type: The component type.
//    public func remove<T: Component>(_ type: T.Type) {
//        components.removeValue(forKey: T.type)
//    }
//}
//
//// MARK: - Name helpers
//
//extension Object {
//    /// The name of the object prefixed with "a" or "an", or "something" if unnamed.
//    public var aName: String {
//        guard let name = self.name, !name.isEmpty else {
//            return "something"
//        }
//        let firstLetter = name.lowercased().first
//        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
//        let article = if let firstLetter, vowels.contains(firstLetter) { "an" } else { "a" }
//        return "\(article) \(name)"
//    }
//
//    /// The name of the object prefixed with "the", or "that" if unnamed.
//    public var theName: String {
//        if let name = self.find(DescriptionComponent.self)?.name {
//            "the \(name)"
//        } else {
//            "that"
//        }
//    }
//}
//
//// MARK: - Accessibility Helper
//
//extension Object {
//    /// Checks if the object is accessible to a given actor (usually the player).
//    ///
//    /// An object is accessible if it's directly in the actor's inventory
//    /// or in the same location as the actor.
//    ///
//    /// - Parameters:
//    ///   - actorID: The ID of the actor trying to access the object.
//    ///   - world: The game world to check locations within.
//    /// - Returns: `true` if the object is accessible, `false` otherwise.
//    public func isAccessible(to actorID: Object.ID, in world: World) -> Bool {
//        guard let locationComponent = self.find(LocationComponent.self) else {
//            // Object has no location, shouldn't be accessible unless it's the actor itself?
//            return self.id == actorID
//        }
//
//        // Is it directly held by the actor?
//        if locationComponent.parentID == actorID {
//            return true
//        }
//
//        // Is it in the same location as the actor?
//        if let actorLocation = world.location(of: actorID) {
//            return locationComponent.parentID == actorLocation.id
//        }
//
//        // Actor location not found or object location doesn't match
//        return false
//    }
//}
