import CoreML
import NaturalLanguage

/// A natural language parser for interactive fiction commands, powered by a Core ML model.
public struct Nitfol {
    /// The custom tag scheme used by the Nitfol model.
    let tagScheme = NLTagScheme("Nitfol")

    // MARK: - Tags

    /// Tag identifying the main verb of a command.
    let verbTag = NLTag("verb")

    /// Tag identifying the direct object of a command.
    let directObjectTag = NLTag("directObject")

    /// Tag identifying a preposition.
    let prepositionTag = NLTag("preposition")

    /// Tag identifying a determiner (e.g., "the", "a"). Ignored during parsing.
    let determinerTag = NLTag("determiner")

    /// Tag identifying a modifier (adjective/adverb) for an object.
    let modifierTag = NLTag("modifier")

    /// Tag identifying the indirect object of a command.
    let indirectObjectTag = NLTag("indirectObject")

    /// The Natural Language tagger instance configured with the Nitfol Core ML model.
    let tagger: NLTagger

    /// Initializes the Nitfol parser.
    ///
    /// This loads the compiled Core ML model (`Gloth.mlmodelc`) expected to be
    /// present in the module's resources and configures an `NLTagger`.
    ///
    /// - Throws: `Nitfol.Error.missingGlothModelResource` if the model file cannot be found.
    ///           Any error thrown by `NLModel(contentsOf:)` during model loading.
    public init() throws {
        guard let glothModelURL = Bundle.module.url(
            forResource: "Gloth",
            withExtension: "mlmodelc"
        ) else {
            throw Error.missingGlothModelResource
        }
        let model = try NLModel(contentsOf: glothModelURL)
        tagger = NLTagger(tagSchemes: [tagScheme])
        tagger.setModels([model], forTagScheme: tagScheme)
    }

    /// Parses a raw string input into a structured Nitfol `Command`.
    ///
    /// Attempts a basic interpretation of common command structures, using the configured
    /// `NLTagger` to identify parts of speech (verb, direct object, preposition, indirect
    /// object, modifiers) based on the trained Core ML model.
    ///
    /// - Parameter string: The raw command string entered by the player.
    /// - Returns: A `Command` struct containing the identified components.
    public func parse(_ string: String) -> ParsedCommand {
        var verb: String?
        var directObject: String?
        var directObjectModifiers = [String]()
        var prepositions = [String]()
        var indirectObject: String?
        var indirectObjectModifiers = [String]()
        var modifiers = [String]()

        tagger.string = string
        tagger.enumerateTags(
            in: string.startIndex..<string.endIndex,
            unit: .word,
            scheme: tagScheme,
            options: .omitWhitespace
        ) { (tag, tokenRange) -> Bool in
            guard let tag, tag != determinerTag else { return true }

            let word = String(string[tokenRange]).lowercased()

            switch tag {
            case verbTag:
                if verb == nil {
                    verb = word
                } else {
                    prepositions.append(word)
                }
            case directObjectTag:
                if directObject == nil {
                    directObject = word
                    directObjectModifiers.append(contentsOf: modifiers)
                } else {
                    indirectObject = word
                    indirectObjectModifiers.append(contentsOf: modifiers)
                }
                modifiers.removeAll()
            case prepositionTag:
                prepositions.append(word)
            case modifierTag:
                modifiers.append(word)
            case indirectObjectTag:
                if let indirectObject {
                    modifiers.append(indirectObject)
                }
                indirectObject = word
                indirectObjectModifiers.append(contentsOf: modifiers)
                modifiers.removeAll()
            default:
                break
            }
            return true
        }

        // Fixes edge cases such as `> out` as a shorthand for `exit the [object]`
        if verb == nil && !prepositions.isEmpty {
            verb = prepositions.removeFirst()
        }

        // When indirect object is defined but direct object is not, shift
        // the object and modifiers into the direct object slot.
        if directObject == nil {
            directObject = indirectObject
            directObjectModifiers.append(contentsOf: indirectObjectModifiers)
            indirectObject = nil
            indirectObjectModifiers.removeAll()
        }

        return .init(
            verb: verb,
            directObject: directObject,
            directObjectModifiers: directObjectModifiers,
            prepositions: prepositions,
            indirectObject: indirectObject,
            indirectObjectModifiers: indirectObjectModifiers
        )
    }
}

/// Errors specific to the Nitfol parser.
extension Nitfol {
    /// Represents errors that can occur during Nitfol initialization or parsing.
    enum Error: Swift.Error {
        /// Thrown when `Sources/Nitfol/Resources/Gloth.mlmodelc` cannot be found.
        case missingGlothModelResource
    }
}
