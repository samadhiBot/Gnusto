import CustomDump
import Testing

@testable import GnustoEngine

@Suite("MarkdownParser Tests")
struct MarkdownParserTests {

    @Test("Orphan prevention - user's specific example")
    func testOrphanPreventionUserExample() {
        // Test the exact example from the user's question
        let input = "You can’t put the bag in the box, because the box is inside the bag."
        let result = MarkdownParser.parse(input, columns: 64)

        print("Input: \(input)")
        print("Result: \(result)")

        let lines = result.components(separatedBy: "\n")
        print("Lines: \(lines)")

        // Should prevent single-word orphans
        for (index, line) in lines.enumerated() {
            let words = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            if !words.isEmpty {
                print("Line \(index + 1): '\(line)' has \(words.count) words")
                #expect(words.count >= 2, "Found orphaned word on line \(index + 1): '\(line)'")
            }
        }

        // Verify the specific expected result from the user's example
        #expect(result.contains("inside\nthe bag.") || result.contains("is inside\nthe bag."))
    }

    @Test("Orphan prevention - basic case")
    func testOrphanPrevention() async throws {
        let input = "You can’t put the bag in the box, because the box is inside the bag."
        let result = MarkdownParser.parse(input, columns: 64)

        // Should prevent single-word orphans
        let lines = result.components(separatedBy: "\n")

        // Verify no single-word lines
        for line in lines {
            let words = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            if !words.isEmpty {
                #expect(words.count >= 2, "Found orphaned word: '\(line)'")
            }
        }

        // Verify the specific expected result
        #expect(result.contains("inside\nthe bag.") || result.contains("is inside\nthe bag."))
    }

    @Test("Orphan prevention - multiple paragraphs")
    func testOrphanPreventionMultipleParagraphs() async throws {
        let input = """
            This is a very long sentence that should wrap and potentially create an orphan word.

            Another paragraph that might also have orphan issues when wrapped.
            """

        let result = MarkdownParser.parse(input, columns: 40)
        let paragraphs = result.components(separatedBy: "\n\n")

        for paragraph in paragraphs {
            let lines = paragraph.components(separatedBy: "\n")
            for line in lines {
                let words = line.trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                if !words.isEmpty {
                    #expect(words.count >= 2, "Found orphaned word in paragraph: '\(line)'")
                }
            }
        }
    }

    @Test("Orphan prevention - short text unchanged")
    func testOrphanPreventionShortText() async throws {
        let input = "Short text."
        let result = MarkdownParser.parse(input, columns: 64)

        // Short text should remain unchanged
        #expect(result == "Short text.")
    }

    @Test("Orphan prevention - single line unchanged")
    func testOrphanPreventionSingleLine() async throws {
        let input = "This is a single line that fits within the column limit."
        let result = MarkdownParser.parse(input, columns: 64)

        // Single line should remain unchanged
        let lines = result.components(separatedBy: "\n")
        #expect(lines.count == 1)
    }

    @Test("Orphan prevention - handles edge cases")
    func testOrphanPreventionEdgeCases() async throws {
        // Test with very short previous line
        let input =
            "A very very very very very very very very very very very long sentence that wraps and might create orphan."
        let result = MarkdownParser.parse(input, columns: 20)

        let lines = result.components(separatedBy: "\n")
        for line in lines {
            let words = line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            if !words.isEmpty {
                #expect(words.count >= 2, "Found orphaned word: '\(line)'")
            }
        }
    }
}
