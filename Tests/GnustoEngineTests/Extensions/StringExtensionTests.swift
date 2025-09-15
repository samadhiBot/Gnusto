import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("String Extensions")
struct StringExtensionTests {

    // MARK: - capitalizedFirst Tests

    @Test("capitalizedFirst capitalizes first letter of lowercase string")
    func testCapitalizedFirstLowercase() {
        #expect("hello".capitalizedFirst == "Hello")
        #expect("world".capitalizedFirst == "World")
        #expect("swift".capitalizedFirst == "Swift")
    }

    @Test("capitalizedFirst handles already capitalized strings")
    func testCapitalizedFirstAlreadyCapitalized() {
        #expect("Hello".capitalizedFirst == "Hello")
        #expect("World".capitalizedFirst == "World")
        #expect("SWIFT".capitalizedFirst == "SWIFT")
    }

    @Test("capitalizedFirst handles empty strings")
    func testCapitalizedFirstEmpty() {
        #expect("".capitalizedFirst == "")
    }

    @Test("capitalizedFirst handles single character strings")
    func testCapitalizedFirstSingleCharacter() {
        #expect("a".capitalizedFirst == "A")
        #expect("A".capitalizedFirst == "A")
        #expect("1".capitalizedFirst == "1")
        #expect("!".capitalizedFirst == "!")
    }

    @Test("capitalizedFirst handles strings starting with numbers or symbols")
    func testCapitalizedFirstNonLetter() {
        #expect("123abc".capitalizedFirst == "123abc")
        #expect("!hello".capitalizedFirst == "!hello")
        #expect("@world".capitalizedFirst == "@world")
    }

    @Test("capitalizedFirst handles strings with whitespace")
    func testCapitalizedFirstWithWhitespace() {
        #expect(" hello".capitalizedFirst == " hello")
        #expect("\thello".capitalizedFirst == "\thello")
        #expect("\nhello".capitalizedFirst == "\nhello")
    }

    @Test("capitalizedFirst handles unicode characters")
    func testCapitalizedFirstUnicode() {
        #expect("émilie".capitalizedFirst == "Émilie")
        #expect("café".capitalizedFirst == "Café")
        #expect("naïve".capitalizedFirst == "Naïve")
    }

    // MARK: - capitalizedSentences Tests

    @Test("capitalizedSentences capitalizes first letter of sentences")
    func testCapitalizedSentencesBasic() {
        let input = "hello world. this is a test! how are you?"
        let expected = "Hello world. This is a test! How are you?"
        #expect(input.capitalizedSentences == expected)
    }

    @Test("capitalizedSentences handles empty strings")
    func testCapitalizedSentencesEmpty() {
        #expect("".capitalizedSentences == "")
    }

    @Test("capitalizedSentences handles single sentences")
    func testCapitalizedSentencesSingle() {
        #expect("hello world".capitalizedSentences == "Hello world")
        #expect("this is a test.".capitalizedSentences == "This is a test.")
    }

    @Test("capitalizedSentences handles multiple sentence endings")
    func testCapitalizedSentencesMultipleEndings() {
        let input = "first sentence. second sentence! third sentence? fourth sentence."
        let expected = "First sentence. Second sentence! Third sentence? Fourth sentence."
        #expect(input.capitalizedSentences == expected)
    }

    @Test("capitalizedSentences handles sentences with extra whitespace")
    func testCapitalizedSentencesExtraWhitespace() {
        let input = "first sentence.  second sentence!   third sentence?"
        let expected = "First sentence.  Second sentence!   Third sentence?"
        #expect(input.capitalizedSentences == expected)
    }

    @Test("capitalizedSentences handles sentences without spaces after punctuation")
    func testCapitalizedSentencesNoSpaces() {
        let input = "first.second!third?fourth"
        let expected = "First.Second!Third?Fourth"
        #expect(input.capitalizedSentences == expected)
    }

    @Test("capitalizedSentences preserves already capitalized letters")
    func testCapitalizedSentencesPreservesCapitals() {
        let input = "Hello world. This IS a test! HOW are you?"
        let expected = "Hello world. This IS a test! HOW are you?"
        #expect(input.capitalizedSentences == expected)
    }

    @Test("capitalizedSentences handles strings starting with punctuation")
    func testCapitalizedSentencesStartingPunctuation() {
        #expect("!hello world".capitalizedSentences == "!Hello world")
        #expect("?what is this".capitalizedSentences == "?What is this")
        #expect(".hidden file".capitalizedSentences == ".Hidden file")
    }

    @Test("capitalizedSentences handles strings with only punctuation")
    func testCapitalizedSentencesOnlyPunctuation() {
        #expect("...".capitalizedSentences == "...")
        #expect("!!!".capitalizedSentences == "!!!")
        #expect("???".capitalizedSentences == "???")
    }

    @Test("capitalizedSentences handles mixed case and punctuation")
    func testCapitalizedSentencesMixedCase() {
        let input = "hELLO wORLD. tHIS iS a TeSt! hOW aRE yOU?"
        let expected = "HELLO wORLD. THIS iS a TeSt! HOW aRE yOU?"
        #expect(input.capitalizedSentences == expected)
    }

    @Test("capitalizedSentences handles unicode characters")
    func testCapitalizedSentencesUnicode() {
        let input = "café is nice. émilie agrees! naïve approach?"
        let expected = "Café is nice. Émilie agrees! Naïve approach?"
        #expect(input.capitalizedSentences == expected)
    }

    // MARK: - withIndefiniteArticle Tests

    @Test("withIndefiniteArticle uses 'an' for vowel-starting words")
    func testWithIndefiniteArticleVowels() {
        #expect("apple".withIndefiniteArticle == "an apple")
        #expect("elephant".withIndefiniteArticle == "an elephant")
        #expect("ice cream".withIndefiniteArticle == "an ice cream")
        #expect("orange".withIndefiniteArticle == "an orange")
        #expect("umbrella".withIndefiniteArticle == "an umbrella")
    }

    @Test("withIndefiniteArticle uses 'a' for consonant-starting words")
    func testWithIndefiniteArticleConsonants() {
        #expect("book".withIndefiniteArticle == "a book")
        #expect("cat".withIndefiniteArticle == "a cat")
        #expect("dog".withIndefiniteArticle == "a dog")
        #expect("flower".withIndefiniteArticle == "a flower")
        #expect("guitar".withIndefiniteArticle == "a guitar")
    }

    @Test("withIndefiniteArticle handles case insensitive vowels")
    func testWithIndefiniteArticleCaseInsensitive() {
        #expect("Apple".withIndefiniteArticle == "an Apple")
        #expect("ELEPHANT".withIndefiniteArticle == "an ELEPHANT")
        #expect("Book".withIndefiniteArticle == "a Book")
        #expect("CAT".withIndefiniteArticle == "a CAT")
    }

    @Test("withIndefiniteArticle handles empty strings")
    func testWithIndefiniteArticleEmpty() {
        #expect("".withIndefiniteArticle == "")
    }

    @Test("withIndefiniteArticle handles single character strings")
    func testWithIndefiniteArticleSingleCharacter() {
        #expect("a".withIndefiniteArticle == "an a")
        #expect("A".withIndefiniteArticle == "an A")
        #expect("b".withIndefiniteArticle == "a b")
        #expect("B".withIndefiniteArticle == "a B")
    }

    @Test("withIndefiniteArticle handles numbers and special characters")
    func testWithIndefiniteArticleSpecialCharacters() {
        #expect("8-ball".withIndefiniteArticle == "an 8-ball")
        #expect("2-dollar bill".withIndefiniteArticle == "a 2-dollar bill")
        #expect("!important".withIndefiniteArticle == "a !important")
        #expect("@symbol".withIndefiniteArticle == "a @symbol")
    }

    @Test("withIndefiniteArticle handles unicode characters")
    func testWithIndefiniteArticleUnicode() {
        #expect("émilie".withIndefiniteArticle == "an émilie")
        #expect("café".withIndefiniteArticle == "a café")
        #expect("naïve".withIndefiniteArticle == "a naïve")
    }

    // MARK: - indent Tests

    @Test("indent adds default 3 spaces per tab level")
    func testIndentDefault() {
        let input = "line1\nline2\nline3"
        let expected = "   line1\n   line2\n   line3"
        #expect(input.indent() == expected)
    }

    @Test("indent handles custom tab levels")
    func testIndentCustomTabLevels() {
        let input = "line1\nline2"

        let oneTab = "   line1\n   line2"
        #expect(input.indent(1) == oneTab)

        let twoTabs = "      line1\n      line2"
        #expect(input.indent(2) == twoTabs)

        let threeTabs = "         line1\n         line2"
        #expect(input.indent(3) == threeTabs)
    }

    @Test("indent handles custom tab width")
    func testIndentCustomTabWidth() {
        let input = "line1\nline2"

        let width2 = "  line1\n  line2"
        #expect(input.indent(1, tabWidth: 2) == width2)

        let width4 = "    line1\n    line2"
        #expect(input.indent(1, tabWidth: 4) == width4)

        let width8 = "        line1\n        line2"
        #expect(input.indent(1, tabWidth: 8) == width8)
    }

    @Test("indent handles omitFirst parameter")
    func testIndentOmitFirst() {
        let input = "line1\nline2\nline3"
        let expected = "line1\n   line2\n   line3"
        #expect(input.indent(1, omitFirst: true) == expected)
    }

    @Test("indent handles empty strings")
    func testIndentEmpty() {
        #expect("".indent() == "")
        #expect("".indent(2, tabWidth: 4) == "")
        #expect("".indent(1, omitFirst: true) == "")
    }

    @Test("indent handles single line strings")
    func testIndentSingleLine() {
        #expect("single line".indent() == "   single line")
        #expect("single line".indent(2) == "      single line")
        #expect("single line".indent(1, omitFirst: true) == "single line")
    }

    @Test("indent handles empty lines")
    func testIndentEmptyLines() {
        let input = "line1\n\nline3"
        let expected = "   line1\n\n   line3"
        #expect(input.indent() == expected)
    }

    @Test("indent handles lines with only whitespace")
    func testIndentWhitespaceLines() {
        let input = "line1\n   \nline3"
        let expected = "   line1\n      \n   line3"
        #expect(input.indent() == expected)
    }

    @Test("indent handles zero tabs")
    func testIndentZeroTabs() {
        let input = "line1\nline2"
        #expect(input.indent(0) == input)
    }

    @Test("indent handles zero tab width")
    func testIndentZeroTabWidth() {
        let input = "line1\nline2"
        #expect(input.indent(1, tabWidth: 0) == input)
    }

    // MARK: - multiline Tests

    @Test("multiline formats single line strings with quotes")
    func testMultilineSingleLine() {
        #expect("single line".multiline() == "'single line'")
        #expect("hello world".multiline() == "'hello world'")
        #expect("".multiline() == "''")
    }

    @Test("multiline formats multiline strings with newline and indentation")
    func testMultilineMultipleLines() {
        let input = "line1\nline2\nline3"
        let expected = "\n   line1\n   line2\n   line3"
        #expect(input.multiline() == expected)
    }

    @Test("multiline handles custom tab levels")
    func testMultilineCustomTabs() {
        let input = "line1\nline2"

        let oneTabs = "\n   line1\n   line2"
        #expect(input.multiline(1) == oneTabs)

        let twoTabs = "\n      line1\n      line2"
        #expect(input.multiline(2) == twoTabs)
    }

    @Test("multiline handles empty multiline strings")
    func testMultilineEmptyLines() {
        let input = "\n"
        let expected = "\n\n"
        #expect(input.multiline() == expected)

        let input2 = "line1\n\nline3"
        let expected2 = "\n   line1\n\n   line3"
        #expect(input2.multiline() == expected2)
    }

    // MARK: - Array<String> commaListing Tests

    @Test("commaListing returns empty string for empty array")
    func testCommaListingEmpty() {
        let strings = [String]()
        #expect(strings.commaListing("and") == "")
        #expect(strings.commaListing("or") == "")
    }

    @Test("commaListing returns single item for single element array")
    func testCommaListingSingleElement() {
        let strings = ["apple"]
        #expect(strings.commaListing("and") == "apple")
        #expect(strings.commaListing("or") == "apple")
    }

    @Test("commaListing returns two items with conjunction")
    func testCommaListingTwoElements() {
        let strings = ["apple", "banana"]
        #expect(strings.commaListing("and") == "apple and banana")
        #expect(strings.commaListing("or") == "apple or banana")
    }

    @Test("commaListing returns three items with Oxford comma")
    func testCommaListingThreeElements() {
        let strings = ["apple", "banana", "cherry"]
        #expect(strings.commaListing("and") == "apple, banana, and cherry")
        #expect(strings.commaListing("or") == "apple, banana, or cherry")
    }

    @Test("commaListing sorts items alphabetically")
    func testCommaListingSorting() {
        let strings = ["zebra", "apple", "monkey"]
        #expect(strings.commaListing("and") == "apple, monkey, and zebra")
        #expect(strings.commaListing("or") == "apple, monkey, or zebra")
    }

    @Test("commaListing handles many items")
    func testCommaListingManyItems() {
        let strings = ["dog", "cat", "bird", "fish", "hamster"]
        let expected = "bird, cat, dog, fish, and hamster"
        #expect(strings.commaListing("and") == expected)
    }

    @Test("commaListing handles custom conjunctions")
    func testCommaListingCustomConjunctions() {
        let strings = ["red", "blue", "green"]
        #expect(strings.commaListing("but not") == "blue, green, but not red")
        #expect(strings.commaListing("plus") == "blue, green, plus red")
    }

    @Test("commaListing handles empty strings in array")
    func testCommaListingWithEmptyStrings() {
        let strings = ["", "apple", "banana"]
        #expect(strings.commaListing("and") == ", apple, and banana")
    }

    @Test("commaListing handles duplicate strings")
    func testCommaListingWithDuplicates() {
        let strings = ["apple", "apple", "banana"]
        #expect(strings.commaListing("and") == "apple, apple, and banana")
    }

    // MARK: - Array<String> listWithDefiniteArticles() Tests

    @Test("listWithDefiniteArticles() returns 'nothing' for empty array")
    func testListWithDefiniteArticlesEmpty() {
        let strings = [String]()
        #expect(strings.listWithDefiniteArticles() == "nothing")
    }

    @Test("listWithDefiniteArticles() returns single item with indefinite article")
    func testListWithDefiniteArticlesSingleItem() {
        let strings = ["apple"]
        #expect(strings.listWithDefiniteArticles() == "an apple")
    }

    @Test("listWithDefiniteArticles() returns two items with 'and'")
    func testListWithDefiniteArticlesTwoItems() {
        let strings = ["book", "apple"]
        #expect(strings.listWithDefiniteArticles() == "an apple and a book")
    }

    @Test("listWithDefiniteArticles() returns three items with Oxford comma")
    func testListWithDefiniteArticlesThreeItems() {
        let strings = ["book", "apple", "cherry"]
        #expect(strings.listWithDefiniteArticles() == "an apple, a book, and a cherry")
    }

    @Test("listWithDefiniteArticles() sorts items alphabetically")
    func testListWithDefiniteArticlesSorting() {
        let strings = ["zebra", "apple", "monkey"]
        #expect(strings.listWithDefiniteArticles() == "an apple, a monkey, and a zebra")
    }

    @Test("listWithDefiniteArticles() handles vowel and consonant starts")
    func testListWithDefiniteArticlesVowelConsonant() {
        let strings = ["orange", "book", "apple", "cat"]
        #expect(strings.listWithDefiniteArticles() == "an apple, a book, a cat, and an orange")
    }

    @Test("listWithDefiniteArticles() handles case insensitive vowels")
    func testListWithDefiniteArticlesCaseInsensitive() {
        let strings = ["Apple", "Book", "ELEPHANT"]
        #expect(strings.listWithDefiniteArticles() == "an Apple, a Book, and an ELEPHANT")
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("all extensions work with unicode strings")
    func testAllExtensionsWithUnicode() {
        let unicodeString = "café naïve émilie"

        #expect(unicodeString.capitalizedFirst == "Café naïve émilie")
        #expect(unicodeString.capitalizedSentences == "Café naïve émilie")
        #expect(unicodeString.withIndefiniteArticle == "a café naïve émilie")
        #expect(unicodeString.multiline() == "'café naïve émilie'")
    }

    @Test("extensions handle very long strings")
    func testExtensionsWithLongStrings() {
        let longString = String(repeating: "very long string ", count: 100)

        #expect(longString.capitalizedFirst.hasPrefix("Very long string"))
        #expect(longString.withIndefiniteArticle.hasPrefix("a very long string"))
        #expect(longString.multiline().hasPrefix("'very long string"))
    }

    @Test("extensions handle strings with special characters")
    func testExtensionsWithSpecialCharacters() {
        let specialString = "hello\nworld\ttab!@#$%"

        #expect(specialString.capitalizedFirst == "Hello\nworld\ttab!@#$%")
        #expect(specialString.withIndefiniteArticle == "a hello\nworld\ttab!@#$%")
        // multiline will format this as a multiline string due to \n
        #expect(specialString.multiline().contains("\n"))
    }
}
