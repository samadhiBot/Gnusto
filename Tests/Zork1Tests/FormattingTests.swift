import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct FormattingTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            )
        )
    }

    @Test("Game introduction formatting has correct linebreaks")
    func testIntroductionFormatting() async throws {
        // Just start the game without any commands
        await engine.run()

        // Check that there's no double line break between introduction and location
        await mockIO.expectOutput(
            """
            Zork I: The Great Underground Empire

            ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
            1983 Infocom, Inc. All rights reserved. ZORK is a registered
            trademark of Infocom, Inc. Revision 88 / Serial number 840726

            --- West of House ---

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Visited location shows brief output")
    func testVisitedLocationBriefOutput() async throws {
        try await engine.execute(
            """
            north
            southwest
            north
            """
        )

        // Check that visited locations show brief output (just name)
        await mockIO.expectOutput(
            """
            > north
            --- North of House ---

            You are facing the north side of a white house. There is no
            door here, and all the windows are boarded up. To the north a
            narrow path winds through the trees.

            > southwest
            --- West of House ---

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            > north
            --- North of House ---
            """
        )
    }
}
