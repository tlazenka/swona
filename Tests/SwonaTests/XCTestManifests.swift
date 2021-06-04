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
            testCase(ExtensionsTests.allTests),
            testCase(OrderedSetTests.allTests),
            testCase(BridgeTests.allTests),
        ]
    }
#endif
