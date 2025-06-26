import Foundation
import Markdown

enum MarkdownParser {
    static let defaultColumnWidth: Int = 64

    static func parse(
        _ markdown: String,
        columns: Int = defaultColumnWidth
    ) -> String {
        Document(parsing: markdown)
            .children
            .map {
                $0.format(
                    options: MarkupFormatter.Options(
                        preferredLineLimit: .init(
                            maxLength: columns,
                            breakWith: .softBreak
                        )
                    )
                )
            }
            .joined(separator: "\n")
            .replacing(/\n\n\n+/, with: "\n\n")
            .replacing(/:\n\n-/, with: ":\n-")
            .replacing(/(?m)[ \t]+$/, with: "")
            .preventOrphans()
    }
}

extension String {
    /// Prevents orphaned words (single words on the last line of paragraphs)
    /// by moving words from the previous line when possible.
    fileprivate func preventOrphans() -> String {
        // Split into paragraphs (separated by double newlines)
        let paragraphs = self.components(separatedBy: "\n\n")

        let processedParagraphs = paragraphs.map { paragraph in
            let lines = paragraph.components(separatedBy: "\n")
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

            return newLines.joined(separator: "\n")
        }

        return processedParagraphs.joined(separator: "\n\n")
    }
}
