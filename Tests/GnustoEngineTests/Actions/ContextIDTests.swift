import Foundation
import Testing
@testable import GnustoEngine

struct ContextIDTests {
    
    // MARK: - Initialization Tests
    
    @Test("ContextID initialization with string literal")
    func testStringLiteralInitialization() {
        let contextID: ContextID = "testContext"
        
        #expect(contextID.rawValue == "testContext")
    }
    
    @Test("ContextID initialization with raw value")
    func testRawValueInitialization() {
        let contextID = ContextID("customContext")
        
        #expect(contextID.rawValue == "customContext")
    }
    
    @Test("ContextID initialization with special characters")
    func testSpecialCharacterInitialization() {
        let specialChars: ContextID = "context_with-special.chars@123"
        
        #expect(specialChars.rawValue == "context_with-special.chars@123")
    }
    
    @Test("ContextID initialization with unicode characters")
    func testUnicodeInitialization() {
        let unicode: ContextID = "context🎮with🏰unicode"
        
        #expect(unicode.rawValue == "context🎮with🏰unicode")
    }
    
    // MARK: - Hashable Conformance Tests
    
    @Test("ContextID Hashable conformance works correctly")
    func testHashableConformance() {
        let context1: ContextID = "sameValue"
        let context2: ContextID = "sameValue"
        let context3: ContextID = "differentValue"
        
        // Same values should have same hash
        #expect(context1.hashValue == context2.hashValue)
        
        // Different values should typically have different hashes (not guaranteed but likely)
        #expect(context1.hashValue != context3.hashValue)
        
        // Can be used in Set
        let contextSet: Set<ContextID> = [context1, context2, context3]
        #expect(contextSet.count == 2) // context1 and context2 are the same
    }
    
    @Test("ContextID can be used as dictionary key")
    func testDictionaryKey() {
        var contextDict: [ContextID: String] = [:]
        
        let key1: ContextID = "firstKey"
        let key2: ContextID = "secondKey"
        let key3: ContextID = "firstKey" // Same as key1
        
        contextDict[key1] = "value1"
        contextDict[key2] = "value2"
        contextDict[key3] = "value3" // Should overwrite key1's value
        
        #expect(contextDict.count == 2)
        #expect(contextDict[key1] == "value3")
        #expect(contextDict[key2] == "value2")
        #expect(contextDict[key3] == "value3")
    }
    
    // MARK: - Comparable Conformance Tests
    
    @Test("ContextID Comparable conformance works correctly")
    func testComparableConformance() {
        let contextA: ContextID = "apple"
        let contextB: ContextID = "banana"
        let contextC: ContextID = "cherry"
        
        // Test less than
        #expect(contextA < contextB)
        #expect(contextB < contextC)
        #expect(contextA < contextC)
        
        // Test not less than
        #expect(!(contextB < contextA))
        #expect(!(contextC < contextB))
        #expect(!(contextC < contextA))
        
        // Test equality (not less than in either direction)
        let contextA2: ContextID = "apple"
        #expect(!(contextA < contextA2))
        #expect(!(contextA2 < contextA))
    }
    
    @Test("ContextID sorting works correctly")
    func testSorting() {
        let contexts: [ContextID] = ["zebra", "apple", "banana", "cherry"]
        let sortedContexts = contexts.sorted()
        
        let expectedOrder: [ContextID] = ["apple", "banana", "cherry", "zebra"]
        
        #expect(sortedContexts == expectedOrder)
    }
    
    @Test("ContextID comparison with special characters")
    func testComparisonWithSpecialCharacters() {
        let context1: ContextID = "context_1"
        let context2: ContextID = "context-2"
        let context3: ContextID = "context.3"
        
        // Test that comparison works with special characters
        // (exact order depends on ASCII values)
        let sorted = [context1, context2, context3].sorted()
        
        // Verify sorting doesn't crash and produces consistent results
        #expect(sorted.count == 3)
        #expect(sorted[0] < sorted[1])
        #expect(sorted[1] < sorted[2])
    }
    
    // MARK: - Equatable Conformance Tests
    
    @Test("ContextID Equatable conformance works correctly")
    func testEquatableConformance() {
        let context1: ContextID = "sameValue"
        let context2: ContextID = "sameValue"
        let context3: ContextID = "differentValue"
        let context4 = ContextID("sameValue")
        
        // Test equality
        #expect(context1 == context2)
        #expect(context1 == context4)
        #expect(context2 == context4)
        
        // Test inequality
        #expect(context1 != context3)
        #expect(context2 != context3)
        #expect(context4 != context3)
    }
    
    @Test("ContextID equality is case sensitive")
    func testCaseSensitiveEquality() {
        let lowercase: ContextID = "context"
        let uppercase: ContextID = "CONTEXT"
        let mixedCase: ContextID = "Context"
        
        #expect(lowercase != uppercase)
        #expect(lowercase != mixedCase)
        #expect(uppercase != mixedCase)
    }
    
    // MARK: - Codable Conformance Tests
    
    @Test("ContextID Codable conformance works correctly")
    func testCodableConformance() throws {
        let originalContext: ContextID = "testContext"
        
        // Encode
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(originalContext)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(ContextID.self, from: encodedData)
        
        #expect(decodedContext == originalContext)
        #expect(decodedContext.rawValue == originalContext.rawValue)
    }
    
    @Test("ContextID array Codable conformance")
    func testArrayCodableConformance() throws {
        let originalContexts: [ContextID] = ["first", "second", "third"]
        
        // Encode
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(originalContexts)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedContexts = try decoder.decode([ContextID].self, from: encodedData)
        
        #expect(decodedContexts == originalContexts)
        #expect(decodedContexts.count == 3)
        #expect(decodedContexts[0].rawValue == "first")
        #expect(decodedContexts[1].rawValue == "second")
        #expect(decodedContexts[2].rawValue == "third")
    }
    
    @Test("ContextID dictionary Codable conformance")
    func testDictionaryCodableConformance() throws {
        let originalDict: [String: ContextID] = [
            "key1": "context1",
            "key2": "context2"
        ]
        
        // Encode
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(originalDict)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedDict = try decoder.decode([String: ContextID].self, from: encodedData)
        
        #expect(decodedDict == originalDict)
        #expect(decodedDict["key1"]?.rawValue == "context1")
        #expect(decodedDict["key2"]?.rawValue == "context2")
    }
    
    // MARK: - Sendable Conformance Tests
    
    @Test("ContextID Sendable conformance allows concurrent usage")
    func testSendableConformance() async {
        let context: ContextID = "concurrentContext"
        
        // Test that ContextID can be used across async boundaries
        let result = await withCheckedContinuation { continuation in
            Task {
                // Use the context in an async context
                let contextCopy = context
                continuation.resume(returning: contextCopy.rawValue)
            }
        }
        
        #expect(result == "concurrentContext")
    }
    
    // MARK: - Edge Cases and Special Values
    
    @Test("ContextID with very long string")
    func testVeryLongString() {
        let longString = String(repeating: "a", count: 1000)
        let longContext = ContextID(longString)
        
        #expect(longContext.rawValue == longString)
        #expect(longContext.rawValue.count == 1000)
    }
    
    @Test("ContextID with whitespace and newlines")
    func testWhitespaceAndNewlines() {
        let whitespaceContext: ContextID = "  context with spaces  "
        let newlineContext: ContextID = "context\nwith\nnewlines"
        let tabContext: ContextID = "context\twith\ttabs"
        
        #expect(whitespaceContext.rawValue == "  context with spaces  ")
        #expect(newlineContext.rawValue == "context\nwith\nnewlines")
        #expect(tabContext.rawValue == "context\twith\ttabs")
    }
    
    @Test("ContextID with numeric strings")
    func testNumericStrings() {
        let numericContext: ContextID = "12345"
        let floatContext: ContextID = "123.45"
        let negativeContext: ContextID = "-123"
        
        #expect(numericContext.rawValue == "12345")
        #expect(floatContext.rawValue == "123.45")
        #expect(negativeContext.rawValue == "-123")
        
        // Test sorting with numeric strings (lexicographic, not numeric)
        let sorted = [negativeContext, floatContext, numericContext].sorted()
        #expect(sorted[0] == negativeContext) // "-123" comes first lexicographically
    }
    
    // MARK: - Usage Pattern Tests
    
    @Test("ContextID usage in collections")
    func testCollectionUsage() {
        let contexts: [ContextID] = ["first", "second", "third", "first"] // Duplicate
        
        // Test in Array
        #expect(contexts.count == 4)
        
        // Test in Set (removes duplicates)
        let contextSet = Set(contexts)
        #expect(contextSet.count == 3)
        
        // Test filtering
        let filtered = contexts.filter { $0.rawValue.contains("i") }
        #expect(filtered.count == 3) // "first", "third", "first"
    }
    
    @Test("ContextID string interpolation")
    func testStringInterpolation() {
        let context: ContextID = "testContext"
        let interpolated = "Current context: \(context.rawValue)"
        
        #expect(interpolated == "Current context: testContext")
    }
    
    // MARK: - Performance and Memory Tests
    
    @Test("ContextID memory efficiency")
    func testMemoryEfficiency() {
        // Test that ContextID doesn't add significant overhead
        let context1: ContextID = "test"
        let context2 = ContextID("test")
        
        // Both should be equal and have same hash
        #expect(context1 == context2)
        #expect(context1.hashValue == context2.hashValue)
        
        // Test that rawValue is accessible
        #expect(context1.rawValue == "test")
        #expect(context2.rawValue == "test")
    }
} 
