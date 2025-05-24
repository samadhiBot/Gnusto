import Foundation
import Markdown

enum MarkdownParser {
    static let columns: Int = 64

    static func parse(
        _ markdown: String,
        columns: Int = columns
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
    }
}
