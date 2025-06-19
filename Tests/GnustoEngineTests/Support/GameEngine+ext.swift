@testable import GnustoEngine

extension GameEngine {
    static func test(
        blueprint: GameBlueprint,
        vocabulary: Vocabulary? = nil,
        pronouns: [String: Set<EntityReference>] = [:],
        activeFuses: [FuseID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        globalState: [GlobalID: StateValue] = [:],
        parser: Parser,
        ioHandler: IOHandler
    ) async -> GameEngine {
        await .init(
            blueprint: blueprint,
            vocabulary: vocabulary,
            pronouns: pronouns,
            activeFuses: activeFuses,
            activeDaemons: activeDaemons,
            globalState: globalState,
            parser: parser,
            ioHandler: ioHandler,
            randomNumberGenerator: SeededGenerator()
        )
    }
}
