import Foundation

/// An enumeration representing pronouns and their associated entity references.
///
/// This enum captures different pronoun types used in natural language processing, where each
/// pronoun case is associated with one or more entity references that the pronoun refers to
/// in context. Pronouns are automatically determined based on the grammatical classification of
/// the referenced entities.
public enum Pronoun: Codable, Sendable, Hashable {
    /// The pronoun `her` and its associated `EntityReference`.
    case her(EntityReference)

    /// The pronoun `him` and its associated `EntityReference`.
    case him(EntityReference)

    /// The pronoun `it` and its associated `EntityReference`.
    case it(EntityReference)

    /// The pronoun `them` and its associated `EntityReference`s.
    case them([EntityReference])
}

// MARK: - Factory Methods

extension Pronoun {
    /// Creates an appropriate pronoun for a single entity based on its gender.
    ///
    /// - Parameters:
    ///   - entity: The entity reference to create a pronoun for
    ///   - classification: The grammatical classification of the entity
    /// - Returns: The appropriate singular pronoun (him, her, it) or plural pronoun (them)
    ///            for the entity
    public static func forEntity(
        _ entity: EntityReference,
        classification: Classification
    ) -> Pronoun {
        switch classification {
        case .masculine: .him(entity)
        case .feminine: .her(entity)
        case .neuter: .it(entity)
        case .plural: .them([entity])
        }
    }

    /// Creates a plural pronoun for multiple entities.
    ///
    /// - Parameter entities: The entity references to create a plural pronoun for
    /// - Returns: A `them` pronoun containing all provided entities
    public static func forEntities(_ entities: [EntityReference]) -> Pronoun {
        .them(entities)
    }
}

// MARK: - Properties

extension Pronoun {
    /// Returns all entity references associated with this pronoun.
    ///
    /// For singular pronouns (her, him, it), returns a single-element array. For plural pronouns
    /// (them), returns all associated entity references.
    var entityReferences: [EntityReference] {
        switch self {
        case .her(let reference): [reference]
        case .him(let reference): [reference]
        case .it(let reference): [reference]
        case .them(let references): references
        }
    }

    /// Returns the object pronoun text for this pronoun type.
    ///
    /// - Returns: "her", "him", "it", or "them" based on the pronoun case
    public var objectPronounText: String {
        switch self {
        case .her: "her"
        case .him: "him"
        case .it: "it"
        case .them: "them"
        }
    }

    /// Returns the subject pronoun text for this pronoun type.
    ///
    /// - Returns: "she", "he", "it", or "they" based on the pronoun case
    public var subjectPronounText: String {
        switch self {
        case .her: "she"
        case .him: "he"
        case .it: "it"
        case .them: "they"
        }
    }

    /// Returns the possessive pronoun text for this pronoun type.
    ///
    /// - Returns: "her", "his", "its", or "their" based on the pronoun case
    public var possessivePronounText: String {
        switch self {
        case .her: "her"
        case .him: "his"
        case .it: "its"
        case .them: "their"
        }
    }

    /// Whether this pronoun represents a singular entity.
    ///
    /// - Returns: `true` for her, him, it; `false` for them
    public var isSingular: Bool {
        switch self {
        case .her, .him, .it: true
        case .them: false
        }
    }

    /// Whether this pronoun represents plural entities.
    ///
    /// - Returns: `true` for them; `false` for her, him, it
    public var isPlural: Bool {
        !isSingular
    }
}
