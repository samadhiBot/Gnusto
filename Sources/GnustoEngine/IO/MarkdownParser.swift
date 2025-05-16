import Foundation
import Markdown

enum MarkdownParser {
    static func parse(_ markdown: String) -> String {
        Document(parsing: markdown)
            .children
            .map { $0.format() }
            .joined(separator: "\n")
    }
}
