import Foundation
import GnustoEngine
import GnustoTestSupport
import Zork1

extension GameEngine {
    public static func zork1(
        pre setup: String = "",
        _ commands: String = ""
    ) async -> (GameEngine, MockIOHandler) {
        await GameEngine.test(
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            ),
            ioHandler: MockIOHandler(pre: setup, commands)
        )
    }
}

extension String {
    static let enterKitchen = """
        north
        east
        open window
        west
        """

    static let enterUnderground = """
        \(enterKitchen)
        west
        take all
        move the rug
        open the trap door
        down
        light the lantern
        """
}
