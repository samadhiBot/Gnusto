import Foundation

extension String {
    /// A single line break character (`\n`).
    ///
    /// Use this for consistent line breaks throughout the engine.
    public static var linebreak: String {
        "\n"
    }

    /// A paragraph break consisting of two line break characters (`\n\n`).
    ///
    /// Use this to separate paragraphs in formatted text output.
    public static var paragraph: String {
        "\n\n"
    }

    /// A single space character (` `).
    ///
    /// Use this for consistent spacing throughout the engine.
    public static var space: String {
        " "
    }
}

extension String {
    /// The string with only the first letter capitalized, leaving other characters unchanged.
    ///
    /// This differs from `capitalized` which capitalizes the first letter of every word.
    /// Returns the original string if empty.
    ///
    /// Examples:
    /// - `"hello world"` → `"Hello world"`
    /// - `"iOS development"` → `"IOS development"`
    /// - `""` → `""`
    var capitalizedFirst: String {
        guard let firstCharacter = first else {
            return self
        }
        return String(firstCharacter).uppercased() + dropFirst()
    }

    /// Capitalizes the first letter of each sentence in the string.
    ///
    /// Sentences are detected by the presence of `.`, `!`, or `?` followed by whitespace.
    /// The first character of the string is always capitalized if it's a letter.
    /// Returns the original string if empty.
    ///
    /// Examples:
    /// - `"hello world. how are you?"` → `"Hello world. How are you?"`
    /// - `"test! another sentence."` → `"Test! Another sentence."`
    var capitalizedSentences: String {
        guard !isEmpty else { return self }

        var result = ""
        var index = startIndex
        var isStartOfSentence = true

        while index < endIndex {
            let char = self[index]

            if isStartOfSentence && char.isLetter && char.isLowercase {
                result.append(char.uppercased())
                isStartOfSentence = false
            } else {
                result.append(char)
                if char == "." || char == "!" || char == "?" {
                    isStartOfSentence = true
                } else if !char.isWhitespace {
                    isStartOfSentence = false
                }
            }

            index = self.index(after: index)
        }

        return result
    }

    /// The string with the appropriate possessive form applied.
    ///
    /// Adds `'s` for words not ending in 's', or just `'` for words ending in 's'.
    /// This follows standard English possessive rules.
    ///
    /// Examples:
    /// - `"cat"` → `"cat's"`
    /// - `"cats"` → `"cats'"`
    /// - `"James"` → `"James'"`
    var possessive: String {
        hasSuffix("s") ? "\(self)'" : "\(self)'s"
    }

    /// The string with trailing whitespace removed.
    ///
    /// Uses a regular expression to remove all whitespace characters from the end of the string,
    /// including spaces, tabs, and newlines.
    ///
    /// Examples:
    /// - `"hello world   "` → `"hello world"`
    /// - `"text\n\n"` → `"text"`
    var rightTrimmed: String {
        replacing(/\s+$/, with: "")
    }

    /// The string prepended with the appropriate indefinite article ("a" or "an").
    ///
    /// Uses linguistic rules to determine the correct article:
    /// - "an" for words starting with vowel sounds (a, e, i, o, u, including accented variants)
    /// - "an" for numbers that start with vowel sounds (8, 11, 18)
    /// - "a" for all other cases
    ///
    /// Handles empty strings gracefully by returning them unchanged.
    ///
    /// Examples:
    /// - `"apple"` → `"an apple"`
    /// - `"book"` → `"a book"`
    /// - `"8-bit computer"` → `"an 8-bit computer"`
    /// - `"élève"` → `"an élève"`
    var withIndefiniteArticle: String {
        guard let firstChar = first else {
            return self
        }

        // Handle numbers that start with vowel sounds
        let vowelSoundPrefixes = ["8", "11", "18"]
        for prefix in vowelSoundPrefixes where hasPrefix(prefix) {
            return "an \(self)"
        }

        // Handle vowels (including accented vowels)
        let lowerFirstChar = String(firstChar).lowercased().first!
        let vowels: Set<Character> = [
            "a", "e", "i", "o", "u", "à", "á", "â", "ã", "ä", "å", "è", "é", "ê", "ë", "ì", "í",
            "î", "ï", "ò", "ó", "ô", "õ", "ö", "ù", "ú", "û", "ü",
        ]
        return vowels.contains(lowerFirstChar) ? "an \(self)" : "a \(self)"
    }

    /// Indents each line in the string by the specified number of tab levels.
    ///
    /// - Parameters:
    ///   - tabs: The number of tab levels to indent by. Defaults to 1.
    ///   - tabWidth: The number of spaces per tab level. Defaults to 3.
    ///   - omitFirst: Whether to omit indentation on the first line. Defaults to `false`.
    /// - Returns: The indented string with each line prefixed by the appropriate number of spaces.
    ///            Empty strings are returned unchanged.
    ///
    /// Examples:
    /// - `"line1\nline2".indent()` → `"   line1\n   line2"`
    /// - `"line1\nline2".indent(2, tabWidth: 4)` → `"        line1\n        line2"`
    /// - `"line1\nline2".indent(omitFirst: true)` → `"line1\n   line2"`
    func indent(_ tabs: Int = 1, tabWidth: Int = 3, omitFirst: Bool = false) -> String {
        guard !isEmpty else { return self }
        let spaces = String(repeating: " ", count: tabs * tabWidth)
        let lines = components(separatedBy: .newlines)
            .map { $0.isEmpty ? "" : spaces + $0 }
            .joined(separator: "\n")
        return omitFirst ? lines.trimmingCharacters(in: .whitespacesAndNewlines) : lines
    }

    /// Formats a string for debug output by handling single-line and multi-line cases differently.
    ///
    /// For single-line strings, wraps the content in single quotes.
    /// For multi-line strings, returns the content on a new line with all lines indented.
    ///
    /// - Parameter tabs: The number of tab levels to indent multi-line content by. Defaults to 1.
    /// - Returns: The formatted string, either quoted (single-line) or indented (multi-line).
    ///
    /// Examples:
    /// - `"hello".multiline()` → `"'hello'"`
    /// - `"line1\nline2".multiline()` → `"\n   line1\n   line2"`
    func multiline(_ tabs: Int = 1) -> String {
        let lines = components(separatedBy: .newlines)
        return if lines.count > 1 {
            "\n\(self.indent(tabs))"
        } else {
            "'\(self)'"
        }
    }
}

extension Array where Element == String {
    /// Returns a grammatically correct string listing the elements with the specified conjunction.
    ///
    /// The elements are sorted alphabetically before being formatted. Uses proper Oxford comma
    /// rules for lists with three or more items.
    ///
    /// - Parameter conjunction: The conjunction to use before the last item (e.g., "and", "or").
    /// - Returns: A formatted string listing all elements, or an empty string if the array is empty.
    ///
    /// Examples:
    /// - `["apple"]` → `"apple"`
    /// - `["apple", "banana"]` → `"apple and banana"`
    /// - `["apple", "banana", "cherry"]` → `"apple, banana, and cherry"`
    /// - `[]` → `""`
    func commaListing(_ conjunction: String) -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return self[0]
        default:
            var items = sorted()
            let lastItem = items.removeLast()
            return items.joined(separator: ", ") + (count == 2 ? "" : ",")
                + " \(conjunction) \(lastItem)"
        }
    }

    /// Returns a grammatically correct string listing elements with indefinite articles.
    ///
    /// Each element is prefixed with the appropriate indefinite article ("a" or "an"),
    /// the elements are sorted alphabetically, and proper Oxford comma rules are applied.
    /// Returns "nothing" for an empty array.
    ///
    /// - Parameter conjunction: The conjunction to use before the last item. Defaults to "and".
    /// - Returns: A formatted string with articles, or "nothing" if the array is empty.
    ///
    /// Examples:
    /// - `["apple"]` → `"an apple"`
    /// - `["apple", "banana"]` → `"an apple and a banana"`
    /// - `["apple", "banana", "cherry"]` → `"an apple, a banana, and a cherry"`
    /// - `[]` → `"nothing"`
    func listWithDefiniteArticles(conjunction: String = "and") -> String {
        switch count {
        case 0:
            return "nothing"
        case 1:
            return self[0].withIndefiniteArticle
        default:
            var items = sorted().map(\.withIndefiniteArticle)
            let lastItem = items.removeLast()
            let oxfordComma = count == 2 ? "" : ","
            return "\(items.joined(separator: ", "))\(oxfordComma) \(conjunction) \(lastItem)"
        }
    }
}
