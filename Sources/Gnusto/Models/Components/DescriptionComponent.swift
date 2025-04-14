import Foundation

/// Contains basic information about an object.
public struct DescriptionComponent: Component {
    public static let type: ComponentType = .description

    /// The name of the object
    public let name: String

    /// The full description of the object
    public let description: String

    /// Alternative names that can be used to refer to this object
    public let synonyms: [String]

    /// Adjectives that can be used to describe this object
    public let adjectives: [String]

    public init(
        name: String,
        description: String,
        synonyms: [String] = [],
        adjectives: [String] = []
    ) {
        self.name = name
        self.description = description
        self.synonyms = synonyms
        self.adjectives = adjectives
    }
}
