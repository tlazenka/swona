import XCTest
import Swona

final class ParserTests: XCTestCase {
    func testVariables() throws {
        try assertParseExpression(source: "foo", expected: "[Ref foo]")
    }

    func testLiterals() throws {
        try assertParseExpression(source: "42", expected: "[Lit 42]")
        try assertParseExpression(source: "\"foo\"", expected: "[Lit \"foo\"]")
        try assertParseExpression(source: "true", expected: "[Lit true]")
    }


    func testIfStatements() throws {
        try assertParseExpression(source: "if (x) y else z", expected: "[If [Ref x] [Ref y] [Ref z]]")
        try assertParseExpression(source: "if (x) y", expected: "[If [Ref x] [Ref y] []]")
    }


    func testUnlessStatements() throws {
        try assertParseExpression(source: "unless (x) y else z", expected: "[If [Not [Ref x]] [Ref y] [Ref z]]")
        try assertParseExpression(source: "unless (x) y", expected: "[If [Not [Ref x]] [Ref y] []]")
    }


    func testWhileStatements() throws {
        try assertParseExpression(source: "while (x) y", expected: "[While [Ref x] [Ref y]]")
    }


    func testAssignment() throws {
        try assertParseExpression(source: "foo = bar", expected: "[Assign foo [Ref bar]]")
    }

    func testVars() throws {
        try assertParseExpression(source: "var foo = bar", expected: "[Var foo [Ref bar]]")
    }

    func testVals() throws {
        try assertParseExpression(source: "val foo = bar", expected: "[Val foo [Ref bar]]")
    }

    func testIfAsAnExpression() throws {
        try assertParseExpression(source: "1 + if (true) 2 else 3", expected: "[Plus [Lit 1] [If [Lit true] [Lit 2] [Lit 3]]]")
        try assertParseExpression(source: "if (true) 2 else 3 + 4", expected: "[If [Lit true] [Lit 2] [Plus [Lit 3] [Lit 4]]]")
        try assertParseExpression(source: "(if (true) 2 else 3) + 4", expected: "[Plus [If [Lit true] [Lit 2] [Lit 3]] [Lit 4]]")
    }

    func testUnlessAsAnExpression() throws {
        try assertParseExpression(source: "1 + unless (true) 2 else 3", expected: "[Plus [Lit 1] [If [Not [Lit true]] [Lit 2] [Lit 3]]]")
        try assertParseExpression(source: "unless (true) 2 else 3 + 4", expected: "[If [Not [Lit true]] [Lit 2] [Plus [Lit 3] [Lit 4]]]")
        try assertParseExpression(source: "(unless (true) 2 else 3) + 4", expected: "[Plus [If [Not [Lit true]] [Lit 2] [Lit 3]] [Lit 4]]")
    }

    func testExpressionList() throws {
        try assertParseExpression(source: "{}", expected: "[ExpressionList []]")
        try assertParseExpression(source: "{ x; y; z }", expected: "[ExpressionList [[Ref x], [Ref y], [Ref z]]]")
    }

    func testAssignmentToLiteralIsSyntaxError() throws {
        assertSyntaxError(code: "1 = bar;")
    }


    func testBinaryOperators() throws {
        try assertParseExpression(source: "1 + 2", expected: "[Plus [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 - 2", expected: "[Minus [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 == 2", expected: "[== [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 != 2", expected: "[!= [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 < 2", expected: "[< [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 > 2", expected: "[> [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 <= 2", expected: "[<= [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "1 >= 2", expected: "[>= [Lit 1] [Lit 2]]")
        try assertParseExpression(source: "true && false", expected: "[And [Lit true] [Lit false]]")
        try assertParseExpression(source: "true || false", expected: "[Or [Lit true] [Lit false]]")
    }

    func testNot() throws {
        try assertParseExpression(source: "!x", expected: "[Not [Ref x]]")
    }


    func testOperatorPrecedence() throws {
        try assertParseExpression(source: "a + b == c + d", expected: "[== [Plus [Ref a] [Ref b]] [Plus [Ref c] [Ref d]]]")
        try assertParseExpression(source: "a + (b == c) + d", expected: "[Plus [Plus [Ref a] [== [Ref b] [Ref c]]] [Ref d]]")
        try assertParseExpression(source: "!x + y", expected: "[Plus [Not [Ref x]] [Ref y]]")
        try assertParseExpression(source: "!(x + y)", expected: "[Not [Plus [Ref x] [Ref y]]]")
        try assertParseExpression(source: "a + b * c + d", expected: "[Plus [Plus [Ref a] [Multiply [Ref b] [Ref c]]] [Ref d]]")
        try assertParseExpression(source: "a == b < c", expected: "[== [Ref a] [< [Ref b] [Ref c]]]")
        try assertParseExpression(source: "a == b || c == d && e == f", expected: "[Or [== [Ref a] [Ref b]] [And [== [Ref c] [Ref d]] [== [Ref e] [Ref f]]]]")
    }

    func testFunctionCall() throws {
        try assertParseExpression(source: "foo()", expected: "[Call [Ref foo] []]")
        try assertParseExpression(source: "bar(1)", expected: "[Call [Ref bar] [[Lit 1]]]")
        try assertParseExpression(source: "baz(1, x)", expected: "[Call [Ref baz] [[Lit 1], [Ref x]]]")
        try assertParseExpression(source: "(baz)()", expected: "[Call [Ref baz] []]")
    }

    func testFunctionDefinition() throws {
        try assertParseFunctionDefinition(source: "fun square(x: Int, y: Int): Int = x * x",
                                      expected: "FunctionDefinition(name=square, args=[(x, Int), (y, Int)], returnType=Int, body=[Multiply [Ref x] [Ref x]])")
    }

    func testSamples() throws {
        try assertParseExpression(source:
            """
            if (x == 2 + 2) { var t = "It"; s = t + " worked!" }
            """,
                                  expected:
            """
            [If [== [Ref x] [Plus [Lit 2] [Lit 2]]] [ExpressionList [[Var t [Lit "It"]], [Assign s [Plus [Ref t] [Lit " worked!"]]]]] []]
            """)

        try assertParseFunctionDefinition(source:
            """
            fun fib(i: Int): Int = if (i == 0 || i == 1)
                i
            else
                fib(i-1) + fib(i-2)
            """,
                                          expected:
            """
            FunctionDefinition(name=fib, args=[(i, Int)], returnType=Int, body=[If [Or [== [Ref i] [Lit 0]] [== [Ref i] [Lit 1]]] [Ref i] [Plus [Call [Ref fib] [[Minus [Ref i] [Lit 1]]]] [Call [Ref fib] [[Minus [Ref i] [Lit 2]]]]]])
            """)

        try assertParseFunctionDefinition(source:
            """
            fun square(x: Int) = x * x
            """,
                                          expected:
            """
            FunctionDefinition(name=square, args=[(x, Int)], returnType=null, body=[Multiply [Ref x] [Ref x]])
            """)

        try assertParseFunctionDefinition(source:
            """
            fun cube(x: Int) = x * x * x
            """,
                                          expected:
            """
            FunctionDefinition(name=cube, args=[(x, Int)], returnType=null, body=[Multiply [Multiply [Ref x] [Ref x]] [Ref x]])
            """)
    }

    private func assertSyntaxError(code: String) {
        var thrownError: Error?
        XCTAssertThrowsError(try parseExpression(code: code), "expected syntax error") {
            thrownError = $0
        }
        XCTAssert(thrownError is SyntaxErrorException)
    }

    private func assertParseExpression(source: String, expected: String) throws {
        let expression = try parseExpression(code: source)

        XCTAssertEqual(expected, expression.description, source)
    }

    private func assertParseFunctionDefinition(source: String, expected: String) throws {
        let expression = try parseFunctionDefinition(code: source)

        XCTAssertEqual(expected, expression.description, source)
    }

    static var allTests = [
        ("testVariables", testVariables),
        ("testLiterals", testLiterals),
        ("testIfStatements", testIfStatements),
        ("testUnlessStatements", testUnlessStatements),
        ("testWhileStatements", testWhileStatements),
        ("testAssignment", testAssignment),
        ("testVars", testVars),
        ("testVals", testVals),
        ("testIfAsAnExpression", testIfAsAnExpression),
        ("testUnlessAsAnExpression", testUnlessAsAnExpression),
        ("testExpressionList", testExpressionList),
        ("testAssignmentToLiteralIsSyntaxError", testAssignmentToLiteralIsSyntaxError),
        ("testBinaryOperators", testBinaryOperators),
        ("testNot", testNot),
        ("testOperatorPrecedence", testOperatorPrecedence),
        ("testFunctionCall", testFunctionCall),
        ("testFunctionDefinition", testFunctionDefinition),
        ("testSamples", testSamples),
    ]
}
