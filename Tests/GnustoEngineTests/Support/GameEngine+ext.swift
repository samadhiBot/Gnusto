@testable import GnustoEngine

extension GameEngine {
    static func test(
        blueprint: GameBlueprint = MinimalGame(),
        vocabulary: Vocabulary? = nil,
        pronouns: [String: Set<EntityReference>] = [:],
        activeFuses: [FuseID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        globalState: [GlobalID: StateValue] = [:],
        parser: Parser = StandardParser(),
        ioHandler: MockIOHandler? = nil
    ) async -> (GameEngine, MockIOHandler) {
        let mockIOHandler = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: blueprint,
            vocabulary: vocabulary,
            pronouns: pronouns,
            activeFuses: activeFuses,
            activeDaemons: activeDaemons,
            globalState: globalState,
            parser: parser,
            ioHandler: ioHandler ?? mockIOHandler,
            randomNumberGenerator: SeededGenerator()
        )
        return (engine, ioHandler ?? mockIOHandler)
    }
}
