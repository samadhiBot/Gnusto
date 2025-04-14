import Foundation
import Nitfol

/// A parser that converts Nitfol-processed natural language commands into Gnusto game actions.
public class CommandParser {
    /// The Nitfol parser instance.
    private let nitfol: Nitfol

    /// Creates a new CommandParser, initializing the Nitfol parser.
    ///
    /// - Throws: An error if the Nitfol model (`Gloth.mlmodel`) cannot be loaded.
    public init() throws {
        nitfol = try Nitfol()
    }

    /// Parses a command string into an Action containing the engine's `UserInput` structure.
    ///
    /// This method uses the `Nitfol` library to parse the raw input string and then
    /// maps the result into the engine-internal `UserInput` format, decoupling the rest
    /// of the engine from the Nitfol library.
    ///
    /// - Parameter input: The command string to parse.
    /// - Returns: An `Action.command` containing the mapped `UserInput`.
    public func parse(_ input: String) -> Action {
        // Parse using Nitfol
        let nitfolResult: ParsedCommand = nitfol.parse(input)

        // Map Nitfol.ParsedCommand directly to Gnusto.UserInput
        let userInput = UserInput(
            verb: nitfolResult.verb.map(VerbID.init(stringLiteral:)),
            directObject: nitfolResult.directObject,
            directObjectModifiers: nitfolResult.directObjectModifiers,
            prepositions: nitfolResult.prepositions,
            indirectObject: nitfolResult.indirectObject,
            indirectObjectModifiers: nitfolResult.indirectObjectModifiers,
            rawInput: input // Store original input string
        )

        // Return the Action with the mapped UserInput
        return .command(userInput)
    }
}
