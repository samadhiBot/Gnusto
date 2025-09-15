import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("markdownParser Tests")
struct markdownParserTests {
    @Test("Orphan prevention - basic case")
    func testOrphanPrevention() async throws {
        let markdownParser = MarkdownParser.testParser()
        let preventOrphansParser = MarkdownParser.testParser(preventOrphans: true)
        let input = "You can't put the bag in the box, because the box is inside the bag."

        // Verify the specific expected result
        expectNoDifference(
            markdownParser.parse(input),
            """
            You can't put the bag in the box, because the box is inside the
            bag.
            """
        )

        expectNoDifference(
            preventOrphansParser.parse(input),
            """
            You can't put the bag in the box, because the box is inside
            the bag.
            """
        )
    }

    @Test("Orphan prevention - multiple paragraphs")
    func testOrphanPreventionMultipleParagraphs() async throws {
        let markdownParser = MarkdownParser.testParser(columns: 42)
        let preventOrphansParser = MarkdownParser.testParser(
            columns: 42,
            preventOrphans: true
        )
        let input = """
            This is a very long sentence that should wrap and potentially create an orphan word.

            Another paragraph that might also have orphan issues when wrapped.
            """

        // Verify the specific expected result
        expectNoDifference(
            markdownParser.parse(input),
            """
            This is a very long sentence that should
            wrap and potentially create an orphan
            word.

            Another paragraph that might also have
            orphan issues when wrapped.
            """
        )

        expectNoDifference(
            preventOrphansParser.parse(input),
            """
            This is a very long sentence that should
            wrap and potentially create an
            orphan word.

            Another paragraph that might also have
            orphan issues when wrapped.
            """
        )
    }

    @Test("Orphan prevention - short text unchanged")
    func testOrphanPreventionShortText() async throws {
        let markdownParser = MarkdownParser.testParser(
            preventOrphans: true
        )

        let input = "Short text."
        let result = markdownParser.parse(input)

        // Short text should remain unchanged
        expectNoDifference(result, "Short text.")
    }

    @Test("Orphan prevention - single line unchanged")
    func testOrphanPreventionSingleLine() async throws {
        let markdownParser = MarkdownParser.testParser(
            preventOrphans: true
        )

        let input = "This is a single line that fits within the column limit."
        let result = markdownParser.parse(input)

        // Single line should remain unchanged
        expectNoDifference(result, "This is a single line that fits within the column limit.")
    }

    @Test("Orphan prevention - handles edge cases")
    func testOrphanPreventionEdgeCases() async throws {
        let markdownParser = MarkdownParser.testParser(columns: 27)
        let preventOrphansParser = MarkdownParser.testParser(
            columns: 27,
            preventOrphans: true
        )

        let input = """
            A very very very very very very very very very very very long sentence \
            that wraps and might create orphan.
            """

        // Verify the specific expected result
        expectNoDifference(
            markdownParser.parse(input),
            """
            A very very very very very
            very very very very very
            very long sentence that
            wraps and might create
            orphan.
            """
        )

        expectNoDifference(
            preventOrphansParser.parse(input),
            """
            A very very very very very
            very very very very very
            very long sentence that
            wraps and might
            create orphan.
            """
        )
    }
}
