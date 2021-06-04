import Swona
import XCTest

final class LexerTests: XCTestCase {
    func testEmptySourceHasNoTokens() throws {
        assertNoTokens(source: "")
        assertNoTokens(source: "  ")
        assertNoTokens(source: "  \n \n \t \t ")
    }

    func testKeywords() throws {
        assertTokens(source: "if", tokens: Token.keyword(Token.Keyword.if))
        assertTokens(source: "else", tokens: Token.keyword(Token.Keyword.else))
        assertTokens(source: "fun", tokens: Token.keyword(Token.Keyword.fun))
        assertTokens(source: "var", tokens: Token.keyword(Token.Keyword.var))
        assertTokens(source: "val", tokens: Token.keyword(Token.Keyword.val))
        assertTokens(source: "while", tokens: Token.keyword(Token.Keyword.while))
    }

    func testIdentifiers() {
        assertTokens(source: "foo", tokens: Token.identifier(name: "foo"))
        assertTokens(source: "bar", tokens: Token.identifier(name: "bar"))
    }

    func testOperators() throws {
        assertTokens(source: "+", tokens: Token.operator(Token.Operator.plus))
        assertTokens(source: "-", tokens: Token.operator(Token.Operator.minus))
        assertTokens(source: "*", tokens: Token.operator(Token.Operator.multiply))
        assertTokens(source: "/", tokens: Token.operator(Token.Operator.divide))
        assertTokens(source: "==", tokens: Token.operator(Token.Operator.equalEqual))
        assertTokens(source: "!=", tokens: Token.operator(Token.Operator.notEqual))
        assertTokens(source: "!", tokens: Token.operator(Token.Operator.not))
        assertTokens(source: "<", tokens: Token.operator(Token.Operator.lessThan))
        assertTokens(source: ">", tokens: Token.operator(Token.Operator.greaterThan))
        assertTokens(source: "<=", tokens: Token.operator(Token.Operator.lessThanOrEqual))
        assertTokens(source: ">=", tokens: Token.operator(Token.Operator.greaterThanOrEqual))
        assertTokens(source: "&&", tokens: Token.operator(Token.Operator.and))
        assertTokens(source: "||", tokens: Token.operator(Token.Operator.or))
    }

    func testPunctuation() throws {
        assertTokens(source: "(", tokens: Token.punctuation(Token.Punctuation.leftParen))
        assertTokens(source: ")", tokens: Token.punctuation(Token.Punctuation.rightParen))
        assertTokens(source: "{", tokens: Token.punctuation(Token.Punctuation.leftBrace))
        assertTokens(source: "}", tokens: Token.punctuation(Token.Punctuation.rightBrace))
        assertTokens(source: "=", tokens: Token.punctuation(Token.Punctuation.equal))
        assertTokens(source: ":", tokens: Token.punctuation(Token.Punctuation.colon))
        assertTokens(source: ";", tokens: Token.punctuation(Token.Punctuation.semicolon))
        assertTokens(source: ",", tokens: Token.punctuation(Token.Punctuation.comma))
    }

    func testLiteralNumbers() {
        assertTokens(source: "42", tokens: Token.literal(value: .integer(value: 42)))
    }

    func testLiteralBooleans() {
        assertTokens(source: "true", tokens: Token.literal(value: Value.bool(value: true)))
        assertTokens(source: "false", tokens: Token.literal(value: Value.bool(value: false)))
    }

    func testLiteralStrings() {
        assertTokens(source: "\"\"", tokens: Token.literal(value: Value.string(value: "")))
        assertTokens(source: "\"foo\"", tokens: Token.literal(value: Value.string(value: "foo")))
        assertTokens(source: "\"bar \\\"baz\\\" quux\"", tokens: Token.literal(value: Value.string(value: "bar \"baz\" quux")))
    }

    func testUnterminatedStringLiteral() throws {
        assertSyntaxError(source: "\"bar")
    }

    func testUnexpectedCharacter() throws {
        assertSyntaxError(source: "€")
    }

    func testMultipleTokens() throws {
        assertTokens(source: "if (foo) \"bar\" else 42",
                     tokens: Token.keyword(.if), .punctuation(.leftParen), .identifier(name: "foo"), .punctuation(.rightParen), .literal(value: Value.string(value: "bar")), .keyword(.else), .literal(value: Value.integer(value: 42)))
    }

    func testTokenLocations() throws {
        let source = """
        if (foo)
            bar()
        else
            baz()
        """
        let locations = try readAllTokens(source: source).map(\.location)

        XCTAssertTrue([1, 1, 1, 1, 2, 2, 2, 3, 4, 4, 4].elementsEqual(locations.map(\.line)), "lines")
        XCTAssertTrue([1, 1, 1, 1, 2, 2, 2, 3, 4, 4, 4].elementsEqual(locations.map { source.lines().map { String($0) }.firstIndex(of: $0.lineText)! + 1 }), "lineTexts")
        XCTAssertTrue([1, 4, 5, 8, 5, 8, 9, 1, 5, 8, 9].elementsEqual(locations.map(\.column)), "columns")
    }

    func testNextTokenOnEmptyThrowsSyntaxError() throws {
        let lexer = try Lexer(source: " ")
        var thrownError: Error?
        XCTAssertThrowsError(try lexer.readToken(), "Expected syntax error") {
            thrownError = $0
        }
        XCTAssert(thrownError is SyntaxErrorException)
    }

    private func assertTokens(source: String, tokens: Token...) {
        XCTAssertTrue(tokens.elementsEqual(try readAllTokens(source: source).map(\.token)))
    }

    private func assertNoTokens(source: String) {
        assertTokens(source: source)
    }

    private func assertSyntaxError(source: String) {
        var thrownError: Error?
        XCTAssertThrowsError(try readAllTokens(source: source), "Expected syntax error") {
            thrownError = $0
        }
        XCTAssert(thrownError is SyntaxErrorException)
    }

    private func readAllTokens(source: String) throws -> [TokenInfo] {
        let lexer = try Lexer(source: source)
        var result = [TokenInfo]()

        while lexer.hasMore {
            result.append(try lexer.readToken())
        }

        return result
    }

    func testBasicLookAhead() throws {
        let lexer = try LookaheadLexer(source: "foo 123 bar")

        XCTAssertTrue(lexer.hasMore)
        XCTAssertEqual(Token.identifier(name: "foo"), try lexer.peekToken().token)

        XCTAssertTrue(lexer.hasMore)
        XCTAssertEqual(Token.identifier(name: "foo"), try lexer.readToken().token)

        XCTAssertTrue(lexer.hasMore)
        XCTAssertEqual(Token.literal(value: .integer(value: 123)), try lexer.readToken().token)

        XCTAssertTrue(lexer.hasMore)
        XCTAssertEqual(Token.identifier(name: "bar"), try lexer.peekToken().token)
        XCTAssertEqual(Token.identifier(name: "bar"), try lexer.peekToken().token)

        XCTAssertTrue(lexer.hasMore)
        XCTAssertEqual(Token.identifier(name: "bar"), try lexer.readToken().token)

        XCTAssertFalse(lexer.hasMore)
    }

    func testConditionalReading() throws {
        let lexer = try LookaheadLexer(source: "foo fun ()")

        XCTAssertFalse(try lexer.readNextIf(token: Token.identifier(name: "bar")))
        XCTAssertFalse(try lexer.readNextIf(token: Token.keyword(.if)))
        XCTAssertTrue(try lexer.readNextIf(token: Token.identifier(name: "foo")))

        XCTAssertFalse(try lexer.readNextIf(token: Token.punctuation(Token.Punctuation.leftParen)))
        XCTAssertTrue(try lexer.readNextIf(token: Token.keyword(.fun)))

        XCTAssertTrue(try lexer.readNextIf(token: Token.punctuation(Token.Punctuation.leftParen)))
        XCTAssertTrue(try lexer.readNextIf(token: Token.punctuation(Token.Punctuation.rightParen)))

        XCTAssertFalse(lexer.hasMore)
    }

    func testConditionalReadingWorksOnEndOfInput() throws {
        let lexer = try LookaheadLexer(source: "")

        XCTAssertFalse(try lexer.readNextIf(token: Token.punctuation(Token.Punctuation.leftParen)))
    }

    func testExpect() throws {
        let lexer = try LookaheadLexer(source: "()")

        XCTAssertEqual(1, try lexer.expect(expected: Token.punctuation(Token.Punctuation.leftParen)).column)
        XCTAssertEqual(2, try lexer.expect(expected: Token.punctuation(Token.Punctuation.rightParen)).column)

        XCTAssertFalse(lexer.hasMore)
    }

    func testUnmetExpectThrowsError() throws {
        let lexer = try LookaheadLexer(source: "()")
        var thrownError: Error?
        XCTAssertThrowsError(try lexer.expect(expected: .keyword(.fun)), "Expected syntax error") {
            thrownError = $0
        }
        XCTAssert(thrownError is SyntaxErrorException)
    }

    func testDefaultToStringProvidesBasicInfo() throws {
        let location = SourceLocation(file: "dummy.sk", line: 42, column: 14, lineText: "    if (foo) bar() else baz()")

        XCTAssertEqual("[dummy.sk:42:14]", location.description)
    }

    func testStringRepresentationProvidesInformationAboutCurrentLine() {
        let location = SourceLocation(file: "dummy.sk", line: 42, column: 14, lineText: "    if (foo) bar() else baz()")

        XCTAssertEqual("""
        [dummy.sk:42:14]     if (foo) bar() else baz()
                                      ^

        """, location.toLongString())
    }

    static var allTests = [
        ("testEmptySourceHasNoTokens", testEmptySourceHasNoTokens),
        ("testKeywords", testKeywords),
        ("testIdentifiers", testIdentifiers),
        ("testOperators", testOperators),
        ("testPunctuation", testPunctuation),
        ("testLiteralNumbers", testLiteralNumbers),
        ("testLiteralBooleans", testLiteralBooleans),
        ("testLiteralStrings", testLiteralStrings),
        ("testUnterminatedStringLiteral", testUnterminatedStringLiteral),
        ("testUnexpectedCharacter", testUnexpectedCharacter),
        ("testMultipleTokens", testMultipleTokens),
        ("testTokenLocations", testTokenLocations),
        ("testNextTokenOnEmptyThrowsSyntaxError", testNextTokenOnEmptyThrowsSyntaxError),
        ("testBasicLookAhead", testBasicLookAhead),
        ("testConditionalReading", testConditionalReading),
        ("testConditionalReadingWorksOnEndOfInput", testConditionalReadingWorksOnEndOfInput),
        ("testExpect", testExpect),
        ("testUnmetExpectThrowsError", testUnmetExpectThrowsError),
        ("testDefaultToStringProvidesBasicInfo", testDefaultToStringProvidesBasicInfo),
        ("testStringRepresentationProvidesInformationAboutCurrentLine", testStringRepresentationProvidesInformationAboutCurrentLine),
    ]
}
