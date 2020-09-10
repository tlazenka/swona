import XCTest

#if os(Linux)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(LexerTests.allTests),
            testCase(ParserTests.allTests),
            testCase(VMTests.allTests),
            testCase(TranslatorTests.allTests),
            testCase(OptimizerTests.allTests),
            testCase(TypesTests.allTests),
            testCase(HelpersTests.allTests),
            testCase(BridgeTests.allTests),
        ]
    }
#endif
