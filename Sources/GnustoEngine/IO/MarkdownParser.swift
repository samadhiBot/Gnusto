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
    }
}
