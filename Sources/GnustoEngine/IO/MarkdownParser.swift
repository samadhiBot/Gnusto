import Foundation
import Markdown

enum MarkdownParser {
    static func parse(_ markdown: String, columns: Int = 68) -> String {
        Document(parsing: markdown)
            .children
            .map {
                $0.format(options: MarkupFormatter.Options(
                    preferredLineLimit: MarkupFormatter.Options.PreferredLineLimit.init(
                        maxLength: columns,
                        breakWith: MarkupFormatter.Options.PreferredLineLimit.SplittingElement.softBreak
                    )
                ))
            }
            .joined(separator: "\n")
            .replacing(/\n\n\n+/, with: "\n\n")
    }
}
