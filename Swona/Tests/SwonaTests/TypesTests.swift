import XCTest
import class Foundation.Bundle
import Swona

final class TypesTests: XCTestCase {
    func testPrimitiveTypeToString() {
        XCTAssertEqual("String", Type.string.description)
        XCTAssertEqual("Int", Type.int.description)
        XCTAssertEqual("Boolean", Type.boolean.description)

    }
    
    func testFunctionTypeToString() {
        XCTAssertEqual("() -> String", Type.function(.function(argumentTypes: [], returnType: Type.string)).description)
        XCTAssertEqual("(Int) -> Boolean", Type.function(.function(argumentTypes: [Type.int], returnType: Type.boolean)).description)
        XCTAssertEqual("(String, Boolean) -> Int", Type.function(.function(argumentTypes: [Type.string, Type.boolean], returnType: Type.int)).description)
    }

    func testArrayTypeToString() {
        XCTAssertEqual("Array<String>", Type.array(elementType: Type.string).description)
        XCTAssertEqual("Array<Array<String>>", Type.array(elementType: Type.array(elementType: Type.string)).description)
        
    }
    
    var env: StaticEnvironment = GlobalStaticEnvironment()
    
    func testLiteralTypes() throws {
        assertType(expectedType: Type.string, code: "\"foo\"")
        assertType(expectedType: Type.int, code: "123")
        assertType(expectedType: Type.boolean, code: "true")
    }
    
    
    func testBoundVariableTypes() throws {
        try env.bind(name: "s", type: Type.string)
        try env.bind(name: "b", type: Type.boolean)
    
        assertType(expectedType: Type.string, code: "s")
        assertType(expectedType: Type.boolean, code: "b")
    }
    
    
    func testNot() throws {
        assertType(expectedType: Type.boolean, code: "!true")
        assertTypeCheckFails(code: "!1")
    }
    
    
    func testEqualityComparison() throws {
        assertType(expectedType: Type.boolean, code: "true == false")
        assertType(expectedType: Type.boolean, code: "1 == 1")
        assertType(expectedType: Type.boolean, code: "\"foo\" == \"bar\"")
    
        assertType(expectedType: Type.boolean, code: "true != false")
        assertType(expectedType: Type.boolean, code: "1 != 1")
        assertType(expectedType: Type.boolean, code: "\"foo\" != \"bar\"")
    
        assertTypeCheckFails(code: "true == 1")
        assertTypeCheckFails(code: "true != 1")
    }
    
    
    func testNumericOperators() throws {
        assertType(expectedType: Type.int, code: "1 + 1")
        assertType(expectedType: Type.int, code: "1 - 1")
    
        assertTypeCheckFails(code: "1 + true")
        assertTypeCheckFails(code: "true + 1")
        assertTypeCheckFails(code: "true + true")
        assertTypeCheckFails(code: "1 + \"foo\"")
        assertTypeCheckFails(code: "true + \"foo\"")
    
        assertTypeCheckFails(code: "1 - true")
        assertTypeCheckFails(code: "true - 1")
        assertTypeCheckFails(code: "true - true")
        assertTypeCheckFails(code: "\"foo\" - \"bar\"")
    }
    
    
    func testIfWithoutElseProducesUnit() throws {
        assertType(expectedType: Type.unit, code: "if (true) 42")
    }
    
    
    func testIfWithIncompatibleTypesProducesUnit() throws {
        assertType(expectedType: Type.unit, code: "if (true) 42 else false")
    }
    
    
    func testTypeOfEmptyExpressionListIsUnit() throws {
        assertType(expectedType: Type.unit, code: "{}")
    }
    
    
    func testTypeOfNonEmptyExpressionListIsTypeOfLast() throws {
        assertType(expectedType: Type.int, code: "{ 1 }")
        assertType(expectedType: Type.string, code: "{ 1; \"\" }")
        assertType(expectedType: Type.int, code: "{ 1; \"\"; 3 }")
    }
    
    
    func testIfWithCompatibleTypesReturnsTheCommonType() throws {
        assertType(expectedType: Type.int, code: "if (true) 42 else 31")
        assertType(expectedType: Type.string, code: "if (true) \"foo\" else \"bar\"")
    }
    
    
    func testPlusWithStringLiteral() throws {
        assertType(expectedType: Type.string, code: "\"foo\" + \"bar\"")
        assertType(expectedType: Type.string, code: "\"foo\" + 42")
        assertType(expectedType: Type.string, code: "\"foo\" + true")
    }
    
    
    func testVariableCanBeReboundInNestedEnvironment() throws {
        try env.bind(name: "x", type: Type.boolean)
    
        try typeCheck(code: "if (x) { var x = 42 }")
        try typeCheck(code: "while (x) { var x = 42 }")
    }
    
    
    func testVariableIsVisibleInNestedEnvironment() throws {
        try typeCheck(code: """
            if (true) {
                var x = 4;
                if (true) {
                    var y = x
                }
            }
    """)
    }
    
    
    func testVariablesDefinedByNestedEnvironmentAreNotVisibleOutside() throws {
        assertTypeCheckFails(code: """
            if (true) {
                if (true) {
                    var x = 4
                };
                var y = x
            }
    """)
    }
    
    
    func testUnboundVariables() throws {
        assertTypeCheckFails(code: "x")
        assertTypeCheckFails(code: "x = 4")
    }
    
    
    func testEvaluationFailsForRebindingVariables() throws {
        assertTypeCheckFails(code: "{ var x = 4; var x = 4 }")
    }
    
    
    func testUnboundVariableType() throws {
        assertTypeCheckFails(code: "s")
    }
    
    
    func testAssigningToParameters() throws {
        env = GlobalStaticEnvironment().newScope(args: [("foo", Type.int)])
        assertTypeCheckFails(code: "foo = 42")
    }
    
    
    func testAssignmentToImmutableVariables() throws {
        assertTypeCheckFails(code: """
            if (true) {
                val x = 4;
                x = 2
            }
    """)
    }
    
    
    func testRelationalOperatorsAreNotSupportedForUnit() throws {
        try env.bind(name: "foo", type: Type.unit)
    
        assertTypeCheckFails(code: "foo == foo")
        assertTypeCheckFails(code: "foo != foo")
        assertTypeCheckFails(code: "foo < foo")
        assertTypeCheckFails(code: "foo > foo")
        assertTypeCheckFails(code: "foo <= foo")
        assertTypeCheckFails(code: "foo >= foo")
    }
    
    
    func testRelationalOperatorsAreNotSupportedForFunctions() throws {
        try env.bind(name: "foo", type: Type.function(.function(argumentTypes: [Type.string], returnType: Type.int)))
    
        assertTypeCheckFails(code: "foo == foo")
        assertTypeCheckFails(code: "foo != foo")
        assertTypeCheckFails(code: "foo < foo")
        assertTypeCheckFails(code: "foo > foo")
        assertTypeCheckFails(code: "foo <= foo")
        assertTypeCheckFails(code: "foo >= foo")
    }
    
    private func assertTypeCheckFails(code: String) {
        var thrownError: Error?
        XCTAssertThrowsError(try typeCheck(code: code), "expected type check exception") {
            thrownError = $0
        }
        XCTAssert(thrownError is TypeCheckException)
    }

    private func assertType(expectedType: Type, code: String) {
        XCTAssertEqual(expectedType, try typeCheck(code: code).type)
    }
    
    @discardableResult private func typeCheck(code: String) throws -> TypedExpression {
        return try parseExpression(code: code).typeCheck(env: env)
    }


    static var allTests = [
        ("testPrimitiveTypeToString", testPrimitiveTypeToString),
        ("testFunctionTypeToString", testFunctionTypeToString),
        ("testArrayTypeToString", testArrayTypeToString),
        ("testLiteralTypes", testLiteralTypes),
        ("testBoundVariableTypes", testBoundVariableTypes),
        ("testNot", testNot),
        ("testEqualityComparison", testEqualityComparison),
        ("testNumericOperators", testNumericOperators),
        ("testIfWithoutElseProducesUnit", testIfWithoutElseProducesUnit),
        ("testIfWithIncompatibleTypesProducesUnit", testIfWithIncompatibleTypesProducesUnit),
        ("testTypeOfEmptyExpressionListIsUnit", testTypeOfEmptyExpressionListIsUnit),
        ("testTypeOfNonEmptyExpressionListIsTypeOfLast", testTypeOfNonEmptyExpressionListIsTypeOfLast),
        ("testIfWithCompatibleTypesReturnsTheCommonType", testIfWithCompatibleTypesReturnsTheCommonType),
        ("testPlusWithStringLiteral", testPlusWithStringLiteral),
        ("testVariableCanBeReboundInNestedEnvironment", testVariableCanBeReboundInNestedEnvironment),
        ("testVariableIsVisibleInNestedEnvironment", testVariableIsVisibleInNestedEnvironment),
        ("testVariablesDefinedByNestedEnvironmentAreNotVisibleOutside", testVariablesDefinedByNestedEnvironmentAreNotVisibleOutside),
        ("testUnboundVariables", testUnboundVariables),
        ("testEvaluationFailsForRebindingVariables", testEvaluationFailsForRebindingVariables),
        ("testUnboundVariableType", testUnboundVariableType),
        ("testAssigningToParameters", testAssigningToParameters),
        ("testAssignmentToImmutableVariables", testAssignmentToImmutableVariables),
        ("testRelationalOperatorsAreNotSupportedForUnit", testRelationalOperatorsAreNotSupportedForUnit),
        ("testRelationalOperatorsAreNotSupportedForFunctions", testRelationalOperatorsAreNotSupportedForFunctions),


    ]
}
