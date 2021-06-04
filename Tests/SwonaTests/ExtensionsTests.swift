import XCTest
@testable import Swona

final class ExtensionsTests: XCTestCase {
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
