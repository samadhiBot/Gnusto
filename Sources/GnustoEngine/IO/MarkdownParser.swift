import Foundation
import Markdown

/// A parser that converts Markdown text into formatted plain text suitable for interactive fiction output.
///
/// `MarkdownParser` processes Markdown documents and renders them as formatted text with configurable
/// options for line wrapping, typography, and orphan prevention. It's optimized for terminal-based
/// interactive fiction games where text needs to be readable and well-formatted within specific
/// column constraints.
///
/// ## Features
/// - Configurable column width with automatic line wrapping
/// - Smart typographic substitutions (smart quotes, em dashes, etc.)
/// - Orphan prevention to improve text readability
/// - Preservation of paragraph structure and list formatting
///
/// ## Example Usage
/// ```swift
/// let parser = MarkdownParser(columns: 64, preventOrphans: true)
/// let formatted = parser.parse("# Welcome\n\nThis is a **bold** statement.")
/// ```
public struct MarkdownParser {
    /// The maximum column width for text wrapping, or `nil` for unlimited width.
    let columns: Int?

    /// Whether to prevent orphaned words (single words on the last line of paragraphs).
    let preventOrphans: Bool

    /// Whether to apply smart typographic substitutions like curly quotes and em dashes.
    let makeSmartTypographicSubstitutions: Bool

    /// Creates a new Markdown parser with the specified formatting options.
    ///
    /// - Parameters:
    ///   - columns: Maximum column width for text wrapping. If `nil`, text will not be wrapped.
    ///   - preventOrphans: Whether to prevent single words from appearing alone on the last
    ///                     line of paragraphs.
    ///   - makeSmartTypographicSubstitutions: Whether to convert straight quotes to curly quotes,
    ///                                        double hyphens to em dashes, etc.
    public init(
        columns: Int? = nil,
        preventOrphans: Bool = false,
        makeSmartTypographicSubstitutions: Bool = true
    ) {
        self.columns = columns
        self.preventOrphans = preventOrphans
        self.makeSmartTypographicSubstitutions = makeSmartTypographicSubstitutions
    }

    /// Parses a Markdown string and returns formatted plain text.
    ///
    /// This method processes the input Markdown through several stages:
    /// 1. Parses the Markdown document structure
    /// 2. Applies formatting options (line wrapping, typography)
    /// 3. Normalizes whitespace and paragraph spacing
    /// 4. Optionally prevents orphaned words
    ///
    /// - Parameter markdown: The Markdown text to parse and format.
    /// - Returns: Formatted plain text suitable for display in an interactive fiction game.
    public func parse(_ markdown: String) -> String {
        let markupChildren = Document(
            parsing: markdown,
            options: makeSmartTypographicSubstitutions ? [] : [.disableSmartOpts]
        )
        .children

        let formatOptions =
            if let columns {
                MarkupFormatter.Options(
                    preferredLineLimit: .init(
                        maxLength: columns,
                        breakWith: .softBreak
                    )
                )
            } else {
                MarkupFormatter.Options.default
            }

        let renderedText = markupChildren.map { $0.format(options: formatOptions) }
            .joined(separator: .linebreak)
            .replacing(/\n\n\n+/, with: String.paragraph)
            .replacing(/:\n\n-/, with: ":\n-")
            .replacing(/(?m)[ \t]+$/, with: "")

        return if preventOrphans {
            renderedText.preventOrphans()
        } else {
            renderedText
        }
    }
}

extension MarkdownParser {
    /// Creates a `MarkdownParser` instance optimized for testing scenarios.
    ///
    /// This factory method provides sensible defaults for unit tests:
    /// - 64-column width for consistent output formatting
    /// - Orphan prevention disabled to avoid test brittleness
    /// - Smart typography disabled for predictable character output
    ///
    /// - Parameters:
    ///   - columns: Column width for text wrapping. Defaults to 64.
    ///   - preventOrphans: Whether to prevent orphaned words. Defaults to `false` for testing.
    ///   - makeSmartTypographicSubstitutions: Whether to apply smart typography. Defaults to `false` for testing.
    /// - Returns: A `MarkdownParser` configured for testing.
    public static func testParser(
        columns: Int = 64,
        preventOrphans: Bool = false,
        makeSmartTypographicSubstitutions: Bool = false
    ) -> MarkdownParser {
        MarkdownParser(
            columns: columns,
            preventOrphans: preventOrphans,
            makeSmartTypographicSubstitutions: makeSmartTypographicSubstitutions
        )
    }
}

extension String {
    /// Prevents orphaned words (single words on the last line of paragraphs)
    /// by moving words from the previous line when possible.
    fileprivate func preventOrphans() -> String {
        // Split into paragraphs (separated by double newlines)
        let paragraphs = self.components(separatedBy: String.paragraph)

        let processedParagraphs = paragraphs.map { paragraph in
            let lines = paragraph.components(separatedBy: String.linebreak)
            guard lines.count >= 2 else { return paragraph }

            // Check if the last line has only one word
            let lastLine = lines.last!.trimmingCharacters(in: .whitespaces)
            let lastLineWords = lastLine.components(separatedBy: .whitespaces).filter {
                $0.isNotEmpty
            }

            guard lastLineWords.count == 1 else { return paragraph }

            // Check if the previous line has multiple words
            let previousLine = lines[lines.count - 2].trimmingCharacters(in: .whitespaces)
            let previousLineWords = previousLine.components(separatedBy: .whitespaces).filter {
                $0.isNotEmpty
            }

            guard previousLineWords.count >= 2 else { return paragraph }

            // Move the last word from the previous line to join the orphaned word
            let wordToMove = previousLineWords.last!
            let newPreviousLine = previousLineWords.dropLast().joined(separator: " ")
            let newLastLine = "\(wordToMove) \(lastLine)"

            // Reconstruct the paragraph
            var newLines = Array(lines.dropLast(2))
            newLines.append(newPreviousLine)
            newLines.append(newLastLine)

            return newLines.joined(separator: .linebreak)
        }

        return processedParagraphs.joined(separator: .paragraph)
    }
}
