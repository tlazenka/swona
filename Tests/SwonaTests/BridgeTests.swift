import XCTest
@testable import Swona

final class BridgeTests: XCTestCase {
    func testBridge() throws {
        let b = try Bridge()
        b.x = "string1".value
        XCTAssertEqual(b.x, "string1".value)
        b.x = nil
        XCTAssertNil(b.x)

        b.x = "string2".value
        XCTAssertEqual(b.x, "string2".value)

        b.y = 5.value
        XCTAssertEqual(b.y, 5.value)

        b.z = true.value
        XCTAssertEqual(b.z, true.value)

        b.z = false.value
        XCTAssertEqual(b.z, false.value)
    }

    func testBridgedRuntimeFunctions() throws {
        let b = try Bridge()
        let array = try b.stringArrayOfSize(2.lit, "empty".lit)
        b.x = array
        let value: Value? = b.x
        guard case let .array(elements, elementType) = value! else {
            XCTFail()
            return
        }

        XCTAssertEqual(elements.array, ["empty".value, "empty".value])
        XCTAssertEqual(elementType, Type.string)

        let length = try b.stringArrayLength(b.x)

        XCTAssertEqual(length, 2.value)

        try b.stringArraySet(b.x, 0.lit, "element0".lit)

        let result = try b.stringArrayGet(b.x, 0.lit)

        XCTAssertEqual(result, "element0".value)
    }

    func testCallAsFunction() throws {
        let inc = fun1(name: "inc", argType: .int, returnType: .int, func: {
            arg in
            guard case let .integer(value) = arg else {
                fatalError("Expected int arg, got \(arg)")
            }

            return .integer(value: value + 1)
        })

        let result = inc(1)
        XCTAssertEqual(result as? Value, Value(integerLiteral: 2))
    }

    func testValueArray() throws {
        let array: Value = ["item1", "item2", "item3"]
        guard case let .array(elements, elementType) = array, elementType == .string else {
            XCTFail("Invalid value array")
            return
        }

        XCTAssertEqual(elements.array, ["item1".value, "item2".value, "item3".value])
    }

    static var allTests = [
        ("testBridge", testBridge),
        ("testBridgedRuntimeFunctions", testBridgedRuntimeFunctions),
        ("testCallAsFunction", testCallAsFunction),
        ("testValueArray", testValueArray),
    ]
}
