import Foundation

// Note: Assumes Effect, UserInput, World are available.

/// Handles the "version" command.
struct VersionHandler {

    static func handle(context: CommandContext) -> [Effect]? {
        // Ignore any parameters for now
        // let command = context.userInput // Not needed for version
        // let world = context.world

        // TODO: Get version string from a central config/source?
        let versionString = "Gnusto Engine v0.2.0 (Command Registry Refactor)"

        return [.showText(versionString)]
    }
}
