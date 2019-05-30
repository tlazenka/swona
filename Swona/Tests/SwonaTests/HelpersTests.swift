import XCTest
import class Foundation.Bundle
@testable import Swona

final class HelpersTests: XCTestCase {
    func testOrderedSetWithSingleElement() {
        var orderedSet = OrderedSet<String>()
        XCTAssertEqual(orderedSet.count, 0)
        XCTAssertTrue(orderedSet.isEmpty)
        XCTAssertTrue(orderedSet.append("1"))
        XCTAssertEqual(orderedSet.count, 1)
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertEqual(orderedSet, OrderedSet(["1"]))
        XCTAssertEqual(orderedSet, OrderedSet(arrayLiteral: "1"))
        XCTAssertTrue(orderedSet.contains("1"))
        XCTAssertFalse(orderedSet.isEmpty)
        XCTAssertFalse(orderedSet.append("1"))
        XCTAssertEqual(orderedSet.count, 1)
        XCTAssertFalse(orderedSet.remove("2"))
        XCTAssertTrue(orderedSet.remove("1"))
        XCTAssertFalse(orderedSet.contains("1"))
        XCTAssertEqual(orderedSet.count, 0)
        XCTAssertTrue(orderedSet.isEmpty)
        XCTAssertFalse(orderedSet.remove("1"))
        XCTAssertEqual(orderedSet.count, 0)
        XCTAssertTrue(orderedSet.isEmpty)
    }
    
    func testOrderedSetWithMultipleElements() {
        var orderedSet = OrderedSet<String>()
        XCTAssertEqual(orderedSet.count, 0)
        XCTAssertTrue(orderedSet.append("1"))
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertEqual(orderedSet.array, ["1"])
        XCTAssertTrue(orderedSet.append("2"))
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertEqual(orderedSet.elementToIndex["2"], 1)
        XCTAssertEqual(orderedSet, OrderedSet(["1", "2"]))
        XCTAssertEqual(orderedSet, OrderedSet(arrayLiteral: "1", "2"))
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "2")
        XCTAssertEqual(orderedSet.array, ["1", "2"])
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertEqual(orderedSet.elementToIndex["2"], 1)
        XCTAssertNil(orderedSet.elementToIndex["3"])
        XCTAssertTrue(orderedSet.append("3"))
        XCTAssertEqual(orderedSet.count, 3)
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertEqual(orderedSet.elementToIndex["2"], 1)
        XCTAssertEqual(orderedSet.elementToIndex["3"], 2)
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "2")
        XCTAssertEqual(orderedSet[2], "3")
        
        XCTAssertEqual(orderedSet.array, ["1", "2", "3"])
        XCTAssertTrue(orderedSet.remove("2"))
        XCTAssertEqual(orderedSet.count, 2)
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertNil(orderedSet.elementToIndex["2"])
        XCTAssertEqual(orderedSet.elementToIndex["3"], 1)
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "3")
        
        XCTAssertEqual(orderedSet.array, ["1", "3"])
        XCTAssertEqual(orderedSet, OrderedSet(["1", "3"]))
        XCTAssertEqual(orderedSet.contents, ["1", "3"])
        XCTAssertTrue(orderedSet.append("2"))
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertEqual(orderedSet.elementToIndex["3"], 1)
        XCTAssertEqual(orderedSet.elementToIndex["2"], 2)
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "3")
        XCTAssertEqual(orderedSet[2], "2")
        XCTAssertEqual(orderedSet, OrderedSet(["1", "3", "2"]))
        XCTAssertEqual(orderedSet.contents, ["1", "3", "2"])
        
        XCTAssertTrue(orderedSet.remove("1"))
        XCTAssertEqual(orderedSet.count, 2)
        XCTAssertNil(orderedSet.elementToIndex["1"])
        XCTAssertEqual(orderedSet, OrderedSet(["3", "2"]))
        XCTAssertEqual(orderedSet.contents, ["3", "2"])
        XCTAssertEqual(orderedSet[0], "3")
        XCTAssertEqual(orderedSet[1], "2")
        XCTAssertTrue(orderedSet.append("1"))
        XCTAssertEqual(orderedSet.elementToIndex["1"], 2)
        XCTAssertEqual(orderedSet, OrderedSet(["3", "2", "1"]))
        XCTAssertEqual(orderedSet.contents, ["3", "2", "1"])
        XCTAssertEqual(orderedSet[0], "3")
        XCTAssertEqual(orderedSet[1], "2")
        XCTAssertEqual(orderedSet[2], "1")
        
        XCTAssertTrue(orderedSet.contains("3"))
        XCTAssertFalse(orderedSet.contains("4"))
        XCTAssertNil(orderedSet.elementToIndex["4"])
        
        orderedSet = OrderedSet(["1", "2", "3", "4"])
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "2")
        XCTAssertEqual(orderedSet[2], "3")
        XCTAssertEqual(orderedSet[3], "4")
        XCTAssertTrue(orderedSet.remove("2"))
        XCTAssertEqual(orderedSet.elementToIndex["1"], 0)
        XCTAssertNil(orderedSet.elementToIndex["2"])
        XCTAssertEqual(orderedSet.elementToIndex["3"], 1)
        XCTAssertEqual(orderedSet.elementToIndex["4"], 2)
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "3")
        XCTAssertEqual(orderedSet[2], "4")
        
        orderedSet = OrderedSet(["1", "2", "3", "4"])
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "2")
        XCTAssertEqual(orderedSet[2], "3")
        XCTAssertEqual(orderedSet[3], "4")
        XCTAssertTrue(orderedSet.remove("2"))
        XCTAssertTrue(orderedSet.append("2"))
        XCTAssertEqual(orderedSet[0], "1")
        XCTAssertEqual(orderedSet[1], "3")
        XCTAssertEqual(orderedSet[2], "4")
        XCTAssertEqual(orderedSet[3], "2")
        XCTAssertEqual(orderedSet, OrderedSet(["1", "3", "4", "2"]))
        XCTAssertEqual(orderedSet, OrderedSet(arrayLiteral: "1", "3", "4", "2"))
        
    }
    
    func testOrderedSetFromArray() {
        var orderedSet = OrderedSet(["1", "2", "3"])
        XCTAssertEqual(orderedSet.count, 3)
        XCTAssertEqual(orderedSet.map { $0 + "testing" }, ["1testing", "2testing", "3testing"])
        XCTAssertEqual(orderedSet.enumerated().map { $0.element + "testing" + "\($0.offset)" }, ["1testing0", "2testing1", "3testing2"])
        
        XCTAssert(orderedSet.remove("2"))
        XCTAssertEqual(orderedSet.count, 2)
        XCTAssertEqual(orderedSet.map { $0 + "testing" }, ["1testing", "3testing"])
        XCTAssertEqual(orderedSet.enumerated().map { $0.element + "testing" + "\($0.offset)" }, ["1testing0",  "3testing1"])
    }
    
    func testOrderedSetExtensions() {
        let orderedSet = OrderedSet(["1", "2", "3"])
        var dictionary: [String: OrderedSet<String>] = [:]
        dictionary["a"] = orderedSet
        XCTAssertEqual(orderedSet,  dictionary["a"])
        
        XCTAssertEqual(OrderedSet(["3", "2", "1"]),  OrderedSet(["3", "2", "1"]))
        XCTAssertNotEqual(OrderedSet(["3", "2", "1"]),  OrderedSet(["2", "1"]))
    }
    
    // https://github.com/apple/swift-package-manager/blob/927a57c33cf105748977f4d066a08f84372a87ac/Tests/BasicTests/OrderedSetTests.swift
    // Modified from Swift Package Manager (Apache License, Version 2.0). See LICENSE-THIRD-PARTY in this repo
    func testOrderedSetBasics() {
        // Create an empty set.
        var set = OrderedSet<String>()
        XCTAssertTrue(set.isEmpty)
        XCTAssertEqual(set.contents, [])
        
        // Create a new set with some strings.
        set = OrderedSet(["one", "two", "three"])
        XCTAssertFalse(set.isEmpty)
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
        XCTAssertEqual(set.contents, ["one", "two", "three"])
        
        // Try adding the same item again - the set should be unchanged.
        XCTAssertEqual(set.append("two"), false)
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssertEqual(set[2], "three")
        
        // Remove the last element.
        let three = set.remove("three")
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0], "one")
        XCTAssertEqual(set[1], "two")
        XCTAssert(three)
        
    }
    
    func testSingles() {
        XCTAssertNil([].singleOrNull())
        XCTAssertNil([1, 2].singleOrNull())
        XCTAssertEqual([1].singleOrNull(), 1)
        XCTAssertEqual([2].single(), 2)
    }
    
    func testSumBy() {
        XCTAssertEqual([1].sumBy { $0 + 1 }, 2)
        XCTAssertEqual([1, 2].sumBy { $0 + 1 }, 5)
        XCTAssertEqual([1, 2, 3].sumBy { $0 * 2 }, 12)
        XCTAssertEqual([].sumBy { $0 + 1 }, 0)
    }

    func testSubList() {
        XCTAssertEqual([1].subList(fromIndex: 0, toIndex: 0), [])
        XCTAssertEqual([1, 2].subList(fromIndex: 0, toIndex: 0), [])
        XCTAssertEqual([1].subList(fromIndex: 0, toIndex: 1), [1])
        XCTAssertEqual([1, 2].subList(fromIndex: 0, toIndex: 1), [1])
        XCTAssertEqual([1, 2].subList(fromIndex: 1, toIndex: 1), [])
        XCTAssertEqual([1, 2].subList(fromIndex: 0, toIndex: 2), [1, 2])
        XCTAssertEqual([1, 2].subList(fromIndex: 1, toIndex: 2), [2])
        XCTAssertEqual([1, 2, 3].subList(fromIndex: 1, toIndex: 2), [2])
        XCTAssertEqual([1, 2, 3].subList(fromIndex: 0, toIndex: 2), [1, 2])
        XCTAssertEqual([1, 2, 3].subList(fromIndex: 2, toIndex: 2), [])
        XCTAssertEqual([1, 2, 3].subList(fromIndex: 2, toIndex: 3), [3])
        XCTAssertEqual([1, 2, 3, 4].subList(fromIndex: 2, toIndex: 3), [3])
        XCTAssertEqual([1, 2, 3, 4].subList(fromIndex: 2, toIndex: 4), [3, 4])

    }
    
    func testBoolInt() {
        XCTAssertEqual(Int(true), 1)
        XCTAssertEqual(Int(false), 0)
    }
    
    func testLines() {
        XCTAssertEqual("".lines(), [""])
        XCTAssertEqual("1".lines(), ["1"])
        XCTAssertEqual("1\n2".lines(), ["1", "2"])
        XCTAssertEqual("1\n2\n3".lines(), ["1", "2", "3"])
        XCTAssertEqual("1\n\n2\n3".lines(), ["1", "", "2", "3"])
        XCTAssertEqual("\n1\n\n2\n3\n\n".lines(), ["", "1", "", "2", "3", "", ""])
    }

    func testSubstring() {
        XCTAssertEqual("a".substring(startOffset: 0, endOffset: 0), "")
        XCTAssertEqual("a".substring(startOffset: 0, endOffset: 0), "")
        XCTAssertEqual("a".substring(startOffset: 0, endOffset: 1), "a")
        
        XCTAssertEqual("ab".substring(startOffset: 0, endOffset: 0), "")
        XCTAssertEqual("ab".substring(startOffset: 0, endOffset: 0), "")
        XCTAssertEqual("ab".substring(startOffset: 0, endOffset: 1), "a")
        XCTAssertEqual("ab".substring(startOffset: 1, endOffset: 1), "")
        XCTAssertEqual("ab".substring(startOffset: 1, endOffset: 2), "b")
        XCTAssertEqual("ab".substring(startOffset: 0, endOffset: 2), "ab")

        XCTAssertEqual("abc".substring(startOffset: 0, endOffset: 0), "")
        XCTAssertEqual("abc".substring(startOffset: 1, endOffset: 1), "")
        XCTAssertEqual("abc".substring(startOffset: 1, endOffset: 2), "b")
        XCTAssertEqual("abc".substring(startOffset: 0, endOffset: 2), "ab")
        XCTAssertEqual("abc".substring(startOffset: 1, endOffset: 2), "b")
        XCTAssertEqual("abc".substring(startOffset: 1, endOffset: 3), "bc")
        XCTAssertEqual("abc".substring(startOffset: 0, endOffset: 3), "abc")
        XCTAssertEqual("abc".substring(startOffset: 2, endOffset: 3), "c")
    }
    
    func testPadEnd() {
        XCTAssertEqual("".padEnd(count: 0, padChar: "."), "")
        XCTAssertEqual("".padEnd(count: 1, padChar: "."), ".")
        XCTAssertEqual("".padEnd(count: 4, padChar: "."), "....")
        XCTAssertEqual("a".padEnd(count: 0, padChar: "."), "a")
        XCTAssertEqual("a".padEnd(count: 1, padChar: "."), "a")
        XCTAssertEqual("a".padEnd(count: 4, padChar: "."), "a...")
        XCTAssertEqual("ab".padEnd(count: 4, padChar: "."), "ab..")
    }

    func testPadStart() {
        XCTAssertEqual("".padStart(count: 0, padChar: "."), "")
        XCTAssertEqual("".padStart(count: 1, padChar: "."), ".")
        XCTAssertEqual("".padStart(count: 4, padChar: "."), "....")
        XCTAssertEqual("a".padStart(count: 0, padChar: "."), "a")
        XCTAssertEqual("a".padStart(count: 1, padChar: "."), "a")
        XCTAssertEqual("a".padStart(count: 4, padChar: "."), "...a")
        XCTAssertEqual("ab".padStart(count: 4, padChar: "."), "..ab")
    }

    static var allTests = [
        ("testOrderedSetWithSingleElement", testOrderedSetWithSingleElement),
        ("testOrderedSetWithMultipleElements", testOrderedSetWithMultipleElements),
        ("testOrderedSetFromArray", testOrderedSetFromArray),
        ("testOrderedSetExtensions", testOrderedSetExtensions),
        ("testOrderedSetBasics", testOrderedSetBasics),
        ("testSingles", testSingles),
        ("testSumBy", testSumBy),
        ("testSubList", testSubList),
        ("testBoolInt", testBoolInt),
        ("testSubstring", testSubstring),
        ("testLines", testLines),
        ("testPadEnd", testPadEnd),
        ("testPadStart", testPadStart),
    ]
}
