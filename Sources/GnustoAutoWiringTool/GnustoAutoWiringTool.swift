import ArgumentParser
import Foundation
import Logging

struct GnustoAutoWiringTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auto-wire",
        abstract: """
            Scans game code and generates necessary ID constants, \
            extensions, and GameBlueprint wiring.
            """,
        version: "0.1.0"
    )

    @Option(help: "An output directory for generated content.")
    var output: String

    @Option(help: "A source directory containing files to scan.")
    var source: String

    private var logger: Logger {
        Logger(label: "com.samadhibot.GnustoAutoWiringTool")
    }

    func run() async throws {
        let sourceURL = URL(fileURLWithPath: source)
        let scanner = Scanner(rootURL: sourceURL)
        try scanner.process()
    }
}
