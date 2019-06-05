import XCTest
import class Foundation.Bundle
import Swona

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
    
    static var allTests = [
        ("testBridge", testBridge),
        ("testBridgedRuntimeFunctions", testBridgedRuntimeFunctions),
    ]
}
