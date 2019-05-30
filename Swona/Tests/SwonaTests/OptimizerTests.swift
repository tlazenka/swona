import XCTest
import class Foundation.Bundle
import Swona

final class OptimizerTests: XCTestCase {
    let env = GlobalStaticEnvironment()
    
    func testEvaluateConstantExpressions() throws {
        try assertOptimized(code: "1+1", expectedAST: "[Lit 2]")
        try assertOptimized(code: "3+4*5", expectedAST: "[Lit 23]")
        try assertOptimized(code: "\"foo\" + 4 + true", expectedAST: "[Lit \"foo4true\"]")
        try assertOptimized(code: "!true", expectedAST: "[Lit false]")
        try assertOptimized(code: "!false", expectedAST: "[Lit true]")
        try assertOptimized(code: "4 == 4", expectedAST: "[Lit true]")
        try assertOptimized(code: "4 != 4", expectedAST: "[Lit false]")
        try assertOptimized(code: "4 != 4 == false", expectedAST: "[Lit true]")
    }
    
    func testConstantIf() throws {
        try env.bind(name: "foo", type: Type.function(.function(argumentTypes: [], returnType: Type.unit)))
        try env.bind(name: "bar", type: Type.function(.function(argumentTypes: [], returnType: Type.unit)))
        
        try assertOptimized(code: "if (true) foo()", expectedAST: "[Call [Ref foo] []]")
        try assertOptimized(code: "if (true) foo() else bar()", expectedAST: "[Call [Ref foo] []]")
        try assertOptimized(code: "if (false) foo()", expectedAST: "[ExpressionList []]")
        try assertOptimized(code: "if (false) foo() else bar()", expectedAST: "[Call [Ref bar] []]")
        try assertOptimized(code: "if (1 == 2) foo() else bar()", expectedAST: "[Call [Ref bar] []]")
    }
    
    func testWhileFalse() throws {
        try env.bind(name: "foo", type: Type.function(.function(argumentTypes: [], returnType: Type.unit)))
        
        try assertOptimized(code: "while (false) foo()", expectedAST: "[ExpressionList []]")
        try assertOptimized(code: "while (1 == 2) foo()", expectedAST: "[ExpressionList []]")
    }
    
    func testNot() throws {
        try env.bind(name: "x", type: Type.boolean)
        
        try assertOptimized(code: "!x", expectedAST: "[Not [Ref x]]")
        try assertOptimized(code: "!!x", expectedAST: "[Ref x]")
        try assertOptimized(code: "!!!x", expectedAST: "[Not [Ref x]]")
        try assertOptimized(code: "!!!!x", expectedAST: "[Ref x]")
        try assertOptimized(code: "!!!!!x", expectedAST: "[Not [Ref x]]")
    }
    
    func testPropagateConstantVariables() throws {
        try env.bind(name: "foo", type: Type.function(.function(argumentTypes: [Type.string], returnType: Type.unit)))
        try assertOptimized(code: """
if (true) { val s = "hello"; foo(s + ", world!") }
""",
                            expectedAST:
            
            """
[ExpressionList [[Var [Local 0 (s)] [Lit "hello"]], [Call [Ref foo] [[Lit "hello, world!"]]]]]
""")
    }
    
    
    private func assertOptimized(code: String, expectedAST: String) throws {
        let statement = try parseExpression(code: code).typeCheck(env: env).optimize()
        
        XCTAssertEqual(expectedAST, statement.description, code)
    }
    
    func testSimpleConstantEvaluation() throws {
        try assertConstantEvaluation(code: "1+1", expected: "[Lit 2]")
        try assertConstantEvaluation(code: "6/2", expected: "[Lit 3]")
        try assertConstantEvaluation(code: "\"foo\" + \"bar\"", expected: "[Lit \"foobar\"]")
        try assertConstantEvaluation(code: "\"foo\" + 42", expected: "[Lit \"foo42\"]")
    }
    
    func testDivisionByZeroWillNotBeThrownAtCompileTime() throws {
        try assertConstantEvaluation(code: "1/0", expected: "[Divide [Lit 1] [Lit 0]]")
        try assertConstantEvaluation(code: "(1+1)/(1-1)", expected: "[Divide [Lit 2] [Lit 0]]")
    }
    
    private func assertConstantEvaluation(code: String, expected: String) throws {
        let result = try parseExpression(code: code).typeCheck(env: GlobalStaticEnvironment()).evaluateConstantExpressions()
        XCTAssertEqual(expected, result.description)
    }

    func testOptimizeStoreFollowedByLoad() {
        let block = BasicBlock()
        block += IR.add
        block += IR.localFrameIR(.storeLocal(index: 4, name: "foo"))
        block += IR.localFrameIR(.loadLocal(index: 4, name: "foo"))
        block += IR.multiply
        
        block.peepholeOptimize()
        
        XCTAssertEqual([IR.add, IR.dup, IR.localFrameIR(IR.LocalFrameIR.storeLocal(index: 4, name: "foo")), IR.multiply], block.opCodes)
    }
    
    func testRemoveRedundantStoreAndLoad() {
        let block = BasicBlock()
        block += IR.add
        block += IR.localFrameIR(.loadLocal(index: 4, name: "foo"))
        block += IR.localFrameIR(.storeLocal(index: 4, name: "foo"))
        block += IR.multiply
        
        block.peepholeOptimize()
        
        XCTAssertEqual([IR.add, IR.multiply], block.opCodes)
    }
    
    func testRemoveRedundantPushUnits() {
        let block = BasicBlock()
        block += IR.add
        block += IR.pushUnit
        block += IR.pop
        block += IR.multiply
        
        block.peepholeOptimize()
        
        XCTAssertEqual([IR.add, IR.multiply], block.opCodes)
    }

 
    static var allTests = [
        ("testEvaluateConstantExpressions", testEvaluateConstantExpressions),
        ("testConstantIf", testConstantIf),
        ("testWhileFalse", testWhileFalse),
        ("testNot", testNot),
        ("testPropagateConstantVariables", testPropagateConstantVariables),
        ("testSimpleConstantEvaluation", testSimpleConstantEvaluation),
        ("testDivisionByZeroWillNotBeThrownAtCompileTime", testDivisionByZeroWillNotBeThrownAtCompileTime),
        ("testOptimizeStoreFollowedByLoad", testOptimizeStoreFollowedByLoad),
        ("testRemoveRedundantStoreAndLoad", testRemoveRedundantStoreAndLoad),
        ("testRemoveRedundantPushUnits", testRemoveRedundantPushUnits),
    ]
}
