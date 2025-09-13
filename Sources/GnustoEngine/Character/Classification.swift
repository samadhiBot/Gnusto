import Foundation

/// Grammatical classification for natural language generation.
///
/// This enum combines classical grammatical classification (masculine, feminine, neuter)
/// with grammatical number (plural) to enable proper pronoun selection, article agreement,
/// and verb conjugation in generated text. This simplified linguistic classification system
/// allows the engine to generate grammatically correct references to game entities.
///
/// These are purely grammatical categories for language generation, not identity markers.
public enum Classification: String, Codable, Sendable, Hashable, CaseIterable {
    /// Masculine grammatical classification.
    ///
    /// Used for entities that should be referred to with masculine pronouns
    /// ("he", "him", "his") in generated text.
    case masculine

    /// Feminine grammatical classification.
    ///
    /// Used for entities that should be referred to with feminine pronouns
    /// ("she", "her", "hers") in generated text.
    case feminine

    /// Neuter grammatical classification.
    ///
    /// Used for entities that should be referred to with neuter pronouns
    /// ("it", "its") in generated text. This is the default for most
    /// inanimate objects.
    case neuter

    /// Plural grammatical number.
    ///
    /// Used for entities that should be referred to with plural pronouns
    /// ("they", "them", "their") in generated text.
    case plural
}

// MARK: - Pronoun Resolution

extension Classification {
    /// Returns the appropriate subject pronoun for this gender.
    ///
    /// - Returns: "he", "she", "it", or "they" based on the gender
    public var subjectPronoun: String {
        switch self {
        case .masculine: "he"
        case .feminine: "she"
        case .neuter: "it"
        case .plural: "they"
        }
    }

    /// Returns the appropriate object pronoun for this gender.
    ///
    /// - Returns: "him", "her", "it", or "them" based on the gender
    public var objectPronoun: String {
        switch self {
        case .masculine: "him"
        case .feminine: "her"
        case .neuter: "it"
        case .plural: "them"
        }
    }

    /// Returns the appropriate possessive adjective for this gender.
    ///
    /// - Returns: "his", "her", "its", or "their" based on the gender
    public var possessiveAdjective: String {
        switch self {
        case .masculine: "his"
        case .feminine: "her"
        case .neuter: "its"
        case .plural: "their"
        }
    }

    /// Returns the appropriate possessive pronoun for this gender.
    ///
    /// - Returns: "his", "hers", "its", or "theirs" based on the gender
    public var possessivePronoun: String {
        switch self {
        case .masculine: "his"
        case .feminine: "hers"
        case .neuter: "its"
        case .plural: "theirs"
        }
    }

    /// Returns the appropriate reflexive pronoun for this gender.
    ///
    /// - Returns: "himself", "herself", "itself", or "themselves" based on the gender
    public var reflexivePronoun: String {
        switch self {
        case .masculine: "himself"
        case .feminine: "herself"
        case .neuter: "itself"
        case .plural: "themselves"
        }
    }

    /// Returns the appropriate verb form for this gender.
    ///
    /// This method helps conjugate verbs based on grammatical number. For singular
    /// genders (masculine, feminine, neuter), it returns the singular form. For plural
    /// gender, it returns the plural form.
    ///
    /// - Parameters:
    ///   - singular: The singular form of the verb.
    ///   - plural: The plural form of the verb. If nil, defaults to the common English
    ///             practice of dropping the final "s" of the singular form.
    /// - Returns: The appropriate verb form based on the gender's grammatical number.
    public func verb(_ singular: String, _ plural: String? = nil) -> String {
        switch self {
        case .masculine, .feminine, .neuter:
            singular
        case .plural:
            plural ?? String(singular.dropLast())
        }
    }
}

// MARK: - Verb Agreement

extension Classification {
    /// Returns whether this gender requires singular verb forms.
    ///
    /// - Returns: `true` for masculine, feminine, and neuter; `false` for plural
    public var usesSingularVerbs: Bool {
        self != .plural
    }

    /// Returns the appropriate "to be" verb form for this gender in present tense.
    ///
    /// - Returns: "is" for singular genders, "are" for plural
    public var presentTenseBeVerb: String {
        usesSingularVerbs ? "is" : "are"
    }

    /// Returns the appropriate "to be" verb form for this gender in past tense.
    ///
    /// - Returns: "was" for singular genders, "were" for plural
    public var pastTenseBeVerb: String {
        usesSingularVerbs ? "was" : "were"
    }
}
