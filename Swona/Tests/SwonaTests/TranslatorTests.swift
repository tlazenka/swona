import XCTest
import class Foundation.Bundle
import Swona

final class TranslatorTests: XCTestCase {
    
    func testStackDelta() {
        let block = BasicBlock()
        
        XCTAssertEqual(0, block.stackDelta)
        
        block += IR.push(value: .integer(value: 42))
        XCTAssertEqual(1, block.stackDelta)
        
        block += IR.push(value: .integer(value: 1))
        XCTAssertEqual(2, block.stackDelta)
        
        block += IR.push(value: .integer(value: 42))
        XCTAssertEqual(3, block.stackDelta)
        
        block += IR.add
        XCTAssertEqual(2, block.stackDelta)
        
        block.endWithBranch(trueBlock: BasicBlock(), falseBlock: BasicBlock())
        XCTAssertEqual(1, block.stackDelta)
    }
    
    func testLocalVariableOffsets() {
        let block = BasicBlock()
        
        block += IR.localFrameIR(.loadLocal(index: 0, name: "square"))
        block += IR.localFrameIR(.storeLocal(index: 1, name: "sq"))
    
        XCTAssertEqual(1, block.maxLocalVariableOffset)
    }
    
    func testJumpBackwardsDoesNotMaintainBalance() {
        let graph = BasicBlockGraph()
        
        let end = BasicBlock()
        graph.start += IR.push(value: .integer(value: 42))
        graph.start += IR.push(value: .integer(value: 42))
        graph.start.endWithBranch(trueBlock: graph.start, falseBlock: end)
        end += IR.push(value: .integer(value: 42))
    
        assertInvalidStackUse(graph: graph)
    }
    
    func testStackUnderflow() {
        let graph = BasicBlockGraph()
        
        graph.start += IR.pop
        assertInvalidStackUse(graph: graph)
    }

    private func assertInvalidStackUse(graph: BasicBlockGraph) {
        var thrownError: Error?
        XCTAssertThrowsError(try graph.buildStackDepthMap(), "expected invalid stack use exception") {
            thrownError = $0
        }
        XCTAssert(thrownError is InvalidStackUseException)
    }
    
    let evaluator = Evaluator()

    func testSimpleTranslation() throws {
        try assertTranslation(source: """
            {
                var x = 4 + 1;
                while (x != 0)
                    x = x - 1
            }
            """,
                              expectedInstructionsAsString: """
            0 stack[fp+2] = 5
            1 stack[fp+1] = stack[fp+2] ; store local x
            2 jump 3
            3 stack[fp+2] = stack[fp+1] ; load local x
            4 stack[fp+3] = 0
            5 stack[fp+2] = stack[fp+2] == stack[fp+3]
            6 stack[fp+2] = !stack[fp+2]
            7 jump-if-false stack[fp+2] 14
            8 jump 9
            9 stack[fp+2] = stack[fp+1] ; load local x
            10 stack[fp+3] = 1
            11 stack[fp+2] = stack[fp+2] - stack[fp+3]
            12 stack[fp+1] = stack[fp+2] ; store local x
            13 jump 3
            14 stack[fp+2] = Unit
            15 ret value=stack[fp+2], address=stack[fp+0]
            """)
    }
    
    func testReadMeExample() throws {
        try assertTranslation(source: """
            {
                var x = 4;
                var s = "";
                if (x == 2 + 2) { var t = "It"; s = t + " worked!" }
            }
            """,
                              expectedInstructionsAsString: """
            0 stack[fp+4] = 4
            1 stack[fp+1] = stack[fp+4] ; store local x
            2 stack[fp+4] = ""
            3 stack[fp+2] = stack[fp+4] ; store local s
            4 stack[fp+4] = stack[fp+1] ; load local x
            5 stack[fp+5] = 4
            6 stack[fp+4] = stack[fp+4] == stack[fp+5]
            7 jump-if-false stack[fp+4] 16
            8 jump 9
            9 stack[fp+4] = "It"
            10 stack[fp+5] = stack[fp+4] ; dup
            11 stack[fp+3] = stack[fp+5] ; store local t
            12 stack[fp+5] = " worked!"
            13 stack[fp+4] = stack[fp+4] ++ stack[fp+5]
            14 stack[fp+2] = stack[fp+4] ; store local s
            15 jump 16
            16 stack[fp+4] = Unit
            17 ret value=stack[fp+4], address=stack[fp+0]
            """)
    }
    
    func testRuntimeFunctions() throws {
        try registerRuntimeFunctions(evaluator: evaluator)
        try assertTranslation(source: """
            {
                var a = stringArrayOfSize(3, "");
                var done = false;
                var i = 0;

                while (!done) { stringArraySet(a, i, "" + i); i = i + 1; if (i==stringArrayLength(a)) done=true };

                stringArrayGet(a, 2)
            }
            """,
                              expectedInstructionsAsString: """
            0 stack[fp+4] = 3
            1 stack[fp+5] = ""
            2 stack[fp+6] = heap[2] ; stringArrayOfSize
            3 call stack[fp+6], 2
            4 fp = fp - 4
            5 stack[fp+1] = stack[fp+4] ; store local a
            6 stack[fp+4] = false
            7 stack[fp+2] = stack[fp+4] ; store local done
            8 stack[fp+4] = 0
            9 stack[fp+3] = stack[fp+4] ; store local i
            10 jump 11
            11 stack[fp+4] = stack[fp+2] ; load local done
            12 stack[fp+4] = !stack[fp+4]
            13 jump-if-false stack[fp+4] 40
            14 jump 15
            15 stack[fp+4] = stack[fp+1] ; load local a
            16 stack[fp+5] = stack[fp+3] ; load local i
            17 stack[fp+6] = ""
            18 stack[fp+7] = stack[fp+3] ; load local i
            19 stack[fp+6] = stack[fp+6] ++ stack[fp+7]
            20 stack[fp+7] = heap[5] ; stringArraySet
            21 call stack[fp+7], 3
            22 fp = fp - 4
            23 Nop
            24 stack[fp+4] = stack[fp+3] ; load local i
            25 stack[fp+5] = 1
            26 stack[fp+4] = stack[fp+4] + stack[fp+5]
            27 stack[fp+5] = stack[fp+4] ; dup
            28 stack[fp+3] = stack[fp+5] ; store local i
            29 stack[fp+5] = stack[fp+1] ; load local a
            30 stack[fp+6] = heap[3] ; stringArrayLength
            31 call stack[fp+6], 1
            32 fp = fp - 5
            33 stack[fp+4] = stack[fp+4] == stack[fp+5]
            34 jump-if-false stack[fp+4] 39
            35 jump 36
            36 stack[fp+4] = true
            37 stack[fp+2] = stack[fp+4] ; store local done
            38 jump 39
            39 jump 11
            40 stack[fp+4] = stack[fp+1] ; load local a
            41 stack[fp+5] = 2
            42 stack[fp+6] = heap[4] ; stringArrayGet
            43 call stack[fp+6], 2
            44 fp = fp - 4
            45 ret value=stack[fp+4], address=stack[fp+0]
            """)
    }
    
    private func assertTranslation(source: String, expectedInstructionsAsString: String) throws {
        let instructions = try evaluator.dump(code: source).lines().map { $0.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) }
        let expectedInstructions = expectedInstructionsAsString.lines().map { $0.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) }
        XCTAssertEqual(instructions, expectedInstructions)
    }

    static var allTests = [
        ("testStackDelta", testStackDelta),
        ("testLocalVariableOffsets", testLocalVariableOffsets),
        ("testJumpBackwardsDoesNotMaintainBalance", testJumpBackwardsDoesNotMaintainBalance),
        ("testStackUnderflow", testStackUnderflow),
        ("testSimpleTranslation", testSimpleTranslation),
        ("testReadMeExample", testReadMeExample),
        ("testRuntimeFunctions", testRuntimeFunctions),

    ]
}
