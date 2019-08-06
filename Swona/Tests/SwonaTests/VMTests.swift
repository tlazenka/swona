import XCTest
import class Foundation.Bundle
import Swona

final class VMTests: XCTestCase {
    let evaluator = Evaluator(trace: false)

    func testLiteralEvaluation() throws {
        try assertEvaluation(code: "42", expectedValue: Value.integer(value: 42))
        try assertEvaluation(code: "true", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "\"foo\"", expectedValue: Value.string(value: "foo"))
    }

    func testVariableEvaluation() throws {
        try evaluator.bind(name: "x", value: .integer(value: 123))

        try assertEvaluation(code: "x", expectedValue: .integer(value: 123))
    }

    func testVarStatements() throws {
        try evaluate(code: "var x = 42")

        try assertEvaluation(code: "x", expectedValue: .integer(value: 42))
    }

    func testAssignments() throws {
        try evaluator.bind(name: "x", value: .integer(value: 42))

        try evaluate(code: "x = 123")

        try assertEvaluation(code: "x", expectedValue: .integer(value: 123))
    }

    func testArithmetic() throws {
        try assertEvaluation(code: "1 + 2 * 3 + 4 / 2", expectedValue: .integer(value: 9))
    }

    func testIfExpressions() throws {
        try evaluator.bind(name: "x", value: Value.bool(value: true))
        try evaluator.bind(name: "y", value: .integer(value: 42))
        try evaluator.bind(name: "r", value: .integer(value: 0))

        try evaluate(code: "if (x) r = 123 else r = y")
        try assertEvaluation(code: "r", expectedValue: .integer(value: 123))

        try evaluate(code: "x = false")

        try evaluate(code: "if (x) r = 123 else r = y")
        try assertEvaluation(code: "r", expectedValue: .integer(value: 42))
    }

    func testIfExpressionValues() throws {
        try evaluator.bind(name: "x", value: Value.bool(value: true))

        try assertEvaluation(code: "if (x) 1 else 2", expectedValue: .integer(value: 1))
        try assertEvaluation(code: "if (!x) 1 else 2", expectedValue: .integer(value: 2))
    }

    func testUnlessExpressions() throws {
        try evaluator.bind(name: "x", value: Value.bool(value: true))
        try evaluator.bind(name: "y", value: .integer(value: 42))
        try evaluator.bind(name: "r", value: .integer(value: 0))

        try evaluate(code: "unless (x) r = 123 else r = y")
        try assertEvaluation(code: "r", expectedValue: .integer(value: 42))

        try evaluate(code: "x = false")

        try evaluate(code: "unless (x) r = 123 else r = y")
        try assertEvaluation(code: "r", expectedValue: .integer(value: 123))
    }


    func testUnlessExpressionValues() throws {
        try evaluator.bind(name: "x", value: Value.bool(value: true))

        try assertEvaluation(code: "unless (x) 1 else 2", expectedValue: .integer(value: 2))
        try assertEvaluation(code: "unless (!x) 1 else 2", expectedValue: .integer(value: 1))
    }

    func testBinaryExpressions() throws {
        try assertEvaluation(code: "1 + 2", expectedValue: .integer(value: 3))
        try assertEvaluation(code: "1 - 2", expectedValue: .integer(value: -1))
        try assertEvaluation(code: "1 == 2", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "1 == 1", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 != 2", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 != 1", expectedValue: Value.bool(value: false))
    }

    func testIfWithoutElse() throws {
        try evaluator.bind(name: "r", value: .integer(value: 0))

        try evaluate(code: "if (false) r = 1")
        try assertEvaluation(code: "r", expectedValue: .integer(value: 0))
        try evaluate(code: "if (true) r = 2")
        try assertEvaluation(code: "r", expectedValue: .integer(value: 2))
    }

    func testWhileLoop() throws {
        try evaluator.bind(name: "x", value: .integer(value: 5))
        try evaluator.bind(name: "a", value: .integer(value: 0))
        try evaluator.bind(name: "b", value: .integer(value: 0))

        try evaluate(code: """
                    while (x != 0) {
                        x = x - 1;
                        a = a + 1;
                        b = a + b
                    }
    """)


        try assertEvaluation(code: "x", expectedValue: .integer(value: 0))
        try assertEvaluation(code: "a", expectedValue: .integer(value: 5))
        try assertEvaluation(code: "b", expectedValue: .integer(value: 15))
    }

    func testNot() throws {
        try evaluate(code: "val x = true")
        try assertEvaluation(code: "!x", expectedValue: .bool(value: false))
        try assertEvaluation(code: "!!x", expectedValue: .bool(value: true))
    }

    func testEvaluationFailuresForCoercions() throws {
        assertTypeCheckFails(s: "1 + \"foo\"")
        assertTypeCheckFails(s: "!1")
    }

    func testDirectCalls() throws {
        try defineSquareFunction()
        try assertEvaluation(code: "square(4)", expectedValue: .integer(value: 16))
    }

    func testFunctionCallsThroughLocalVariable() throws {
        try defineSquareFunction()
        try evaluator.bind(name: "result", value: .integer(value: 0))

        try evaluate(code: """
            if (true) {
                var sq = square;
                result = sq(5)
            }
    """)

        try assertEvaluation(code: "result", expectedValue: .integer(value: 25))
    }

    func testFunctionCallsThroughExpression() throws {
        try defineSquareFunction()
        try assertEvaluation(code: "(square)(6)", expectedValue: .integer(value: 36))
    }

    func testExpressionFunctions() throws {
        try evaluate(code:"fun sub(x: Int, y: Int): Int = x - y")
        try assertEvaluation(code: "sub(7, 4)", expectedValue: .integer(value: 3))
    }

    func testEvaluationFailsForUnboundVariables() throws {
        assertTypeCheckFails(s: "x")
        assertTypeCheckFails(s: "x = 4")
    }

    func testLogicalOperators() throws {
        try assertEvaluation(code: "false || false", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "false || true", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "true || false", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "true || true", expectedValue: Value.bool(value: true))

        try assertEvaluation(code: "false && false", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "false && true", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "true && false", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "true && true", expectedValue: Value.bool(value: true))
    }

    func testEvaluationFailsForRebindingVariables() throws {
        assertTypeCheckFails(s: "{ var x = 4; var x = 4 }")
    }

    func testPlusWithStringLiteralOnLeftSideIsStringConcatenation() throws {
        try assertEvaluation(code: "\"foo \" + \"bar\"", expectedValue: Value.string(value: "foo bar"))
        try assertEvaluation(code: "\"foo \" + 42", expectedValue: Value.string(value: "foo 42"))
        try assertEvaluation(code: "\"foo \" + true", expectedValue: Value.string(value: "foo true"))
    }

    func testRelationalOperators() throws {
        try assertEvaluation(code: "1 == 1", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 != 1", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "1 < 1", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "1 <= 1", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 > 1", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "1 >= 1", expectedValue: Value.bool(value: true))

        try assertEvaluation(code: "1 == 2", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "1 != 2", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 < 2", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 <= 2", expectedValue: Value.bool(value: true))
        try assertEvaluation(code: "1 > 2", expectedValue: Value.bool(value: false))
        try assertEvaluation(code: "1 >= 2", expectedValue: Value.bool(value: false))
    }

    func testNativeFunctionCallWithSingleParameter() throws {

        try evaluator.bind(name: "inc",  value: .function(fun1(name: "inc", argType: Type.int, returnType: Type.int) { (value: Value) -> Value in
            return value.plus(rhs: .integer(value: 1))}), mutable: false)

        try assertEvaluation(code: "inc(4)", expectedValue:.integer(value: 5))
    }

    func testNativeFunctionCallWithMultipleParameters() throws {

        try evaluator.bind(name: "sub",  value: .function(fun2(name: "sub", argType: Type.int, returnType: Type.int) { (a: Value, b: Value) -> Value in
            return a.minus(rhs: b)}), mutable: false)

        try assertEvaluation(code: "sub(7, 4)", expectedValue:.integer(value: 3))
    }


    func testNestedIfs() throws {
        try assertEvaluation(code: "if (false) 1 else if (true) 2 else 3", expectedValue: .integer(value: 2))
    }

    func testRecursion() throws {
        try evaluate(code: """
            fun fib(i: Int): Int =
                if (i == 0)
                    0
                else if (i == 1)
                    1
                else
                    fib(i-1) + fib(i-2)
    """)

        try assertEvaluation(code: "fib(2)", expectedValue: .integer(value: 1))
        try assertEvaluation(code: "fib(10)", expectedValue: .integer(value: 55))
        try assertEvaluation(code: "fib(20)", expectedValue: .integer(value: 6765))
    }

    func testRuntimeFunctions() throws {
        try registerRuntimeFunctions(evaluator: evaluator)
        try evaluate(code: #"var a = stringArrayOfSize(3, "")"#)
        try evaluate(code: #"var done = false"#)
        try evaluate(code: #"var i = 0"#)
        try evaluate(code: #"while (!done) { stringArraySet(a, i, "" + i); i = i + 1; if (i==stringArrayLength(a)) done=true }"#)
        try assertEvaluation(code: "stringArrayGet(a, 0)", expectedValue: .string(value: "0"))
        try assertEvaluation(code: "stringArrayGet(a, 1)", expectedValue: .string(value: "1"))
        try assertEvaluation(code: "stringArrayGet(a, 2)", expectedValue: .string(value: "2"))
    }

    private func assertTypeCheckFails(s: String) {
        var thrownError: Error?
        XCTAssertThrowsError(try evaluate(code: s), "expected type check exception") {
            thrownError = $0
        }
        XCTAssert(thrownError is TypeCheckException)
    }

    private func assertEvaluation(code: String, expectedValue: Value) throws {
        evaluator.optimize = true
        XCTAssertEqual(expectedValue, try evaluate(code: code))
        evaluator.optimize = false
        XCTAssertEqual(expectedValue, try evaluate(code: code))
    }

    private func defineSquareFunction() throws {
        try evaluator.evaluate(code: "fun square(x: Int) = x * x")
    }

    @discardableResult private func evaluate(code: String) throws -> Value {
        return try evaluator.evaluate(code: code).value
    }


    static var allTests = [
        ("testLiteralEvaluation", testLiteralEvaluation),
        ("testVariableEvaluation", testVariableEvaluation),
        ("testVarStatements", testVarStatements),
        ("testAssignments", testAssignments),
        ("testArithmetic", testArithmetic),
        ("testIfExpressions", testIfExpressions),
        ("testIfExpressionValues", testIfExpressionValues),
        ("testUnlessExpressions", testUnlessExpressions),
        ("testUnlessExpressionValues", testUnlessExpressions),
        ("testBinaryExpressions", testBinaryExpressions),
        ("testIfWithoutElse", testIfWithoutElse),
        ("testWhileLoop", testWhileLoop),
        ("testNot", testNot),
        ("testEvaluationFailuresForCoercions", testEvaluationFailuresForCoercions),
        ("testDirectCalls", testDirectCalls),
        ("testFunctionCallsThroughLocalVariable", testFunctionCallsThroughLocalVariable),
        ("testFunctionCallsThroughExpression", testFunctionCallsThroughExpression),
        ("testExpressionFunctions", testExpressionFunctions),
        ("testEvaluationFailsForUnboundVariables", testEvaluationFailsForUnboundVariables),
        ("testLogicalOperators", testLogicalOperators),
        ("testEvaluationFailsForRebindingVariables", testEvaluationFailsForRebindingVariables),
        ("testPlusWithStringLiteralOnLeftSideIsStringConcatenation", testPlusWithStringLiteralOnLeftSideIsStringConcatenation),
        ("testRelationalOperators", testRelationalOperators),
        ("testNativeFunctionCallWithSingleParameter", testNativeFunctionCallWithSingleParameter),
        ("testNativeFunctionCallWithMultipleParameters", testNativeFunctionCallWithMultipleParameters),
        ("testNestedIfs", testNestedIfs),
        ("testRecursion", testRecursion),
        ("testRuntimeFunctions", testRuntimeFunctions),
    ]
}
