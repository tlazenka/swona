/**
 * Represents a location in source code.
 *
 * In addition to actual location (file name and position in file) the class also
 * contains reference to the source code in the line, allowing easy printing of
 * context for error messages.
 */

public struct SourceLocation: Equatable, CustomStringConvertible {
    public let file: String, line: Int, column: Int, lineText: String
    public init(file: String, line: Int, column: Int, lineText: String) {
        self.file = file
        self.line = line
        self.column = column
        self.lineText = lineText
    }

    /**
     * Returns single line representation of the location.
     */
    public var description: String { return "[\(file.description):\(line.description):\(column.description)]" }
    
    /**
     * Returns two line representation of the location.
     */
    public func toLongString() -> String {
        let prefix = "[\(file.description):\(line.description):\(column.description)] "
        let indent = String(repeating: " ", count: column - 1 + prefix.count)
        return "\(prefix)\(lineText.description)\n\(indent)^\n"
    }
}

/**
 * Exception thrown when there is a syntax error.
 *
 * Syntax errors can originate either in the lexer or the parser.
 */
open class SyntaxErrorException: Error, CustomStringConvertible {
    public let errorMessage: String, sourceLocation: SourceLocation
    
    init(errorMessage: String, sourceLocation: SourceLocation) {
        self.errorMessage = errorMessage
        self.sourceLocation = sourceLocation
    }
    
    public var description: String {
        return "\(errorMessage)\n\(sourceLocation.toLongString())"
    }
}

/**
 * Exception thrown when there is a syntax error.
 *
 * Syntax errors can originate either in the lexer or the parser.
 */
public class UnexpectedEndOfInputException: SyntaxErrorException {
    init(sourceLocation: SourceLocation) {
        super.init(errorMessage: "unexpected end of input", sourceLocation: sourceLocation)
    }
}


/**
 * Tokens are the indivisible building blocks of source code.
 *
 * [Lexer] analyzes the source string to return tokens to be consumed by the parser.
 *
 * Some tokens are singleton values: e.g. when encountering `if` in the source code,
 * the lexer will return simply [Token.Keyword.If]. Other tokens contain information about
 * the value read: e.g. for source code `123`, the lexer will return [Token.Literal],
 * with its `value` set to integer `123`.
 *
 * @see TokenInfo
 */
public enum Token: CustomStringConvertible {
    /**
     * Identifier such as variable, method or class name.
     */
    case identifier(name: String)
    
    /**
     * Literal value, e.g. `42`, `"foo"`, or `true`.
     */
    case literal(value: Value)
    
    /**
     * Reserved word in the language.
     */
    case keyword(Keyword)
    
    /**
     * Operators.
     */
    case `operator`(Operator)
    
    /**
     * General punctuation.
     */
    case punctuation(Punctuation)
    
    public enum Keyword : String, CustomStringConvertible {
        case `else` = "else"
        case fun = "fun"
        case `if` = "if"
        case `var` = "var"
        case val = "val"
        case `while` = "while"
        
        public var description: String { return self.rawValue.description }
    }
    
    public enum Operator : String, CaseIterable, CustomStringConvertible {
        case plus = "+"
        case minus = "-"
        case multiply = "*"
        case divide = "/"
        case equalEqual = "=="
        case notEqual = "!="
        case not = "!"
        case lessThan = "<"
        case greaterThan = ">"
        case lessThanOrEqual = "<="
        case greaterThanOrEqual = ">="
        case and = "&&"
        case or = "||"
        
        public var description: String { return self.rawValue.description }
    }
    
    public enum Punctuation : String, CaseIterable, CustomStringConvertible {
        case leftParen = "("
        case rightParen = ")"
        case leftBrace = "{"
        case rightBrace = "}"
        case equal = "="
        case colon = ":"
        case semicolon = ";"
        case comma = ","
        
        public var description: String { return "'\(self.rawValue.description)'" }
    }
    public var description: String {
        switch self {
        case let .identifier(name):
            return name.description
        case let .keyword(value):
            return value.description
        case let .operator(value):
            return value.description
        case let .punctuation(value):
            return value.description
        case let .literal(value):
            return value.description
        }
    }
    
}

/**
 * [Token] along its [SourceLocation] in the original source code.
 */
public struct TokenInfo: CustomStringConvertible {
    public let token: Token
    public let location: SourceLocation
    public var description: String { return "[TokenInfo \(token) \(location)]" }
}

/**
 * Lexer converts source code to tokens to be used by parser.
 *
 * @param source the source code to parse
 * @param file name of the file containing the source code. Used for [SourceLocation].
 * @see Token
 * @see TokenInfo
 */
public class Lexer {
    /**
     * Current position in the file (index to [source]).
     *
     * The lexer position always points to start of next token (or the end of input).
     *
     * The invariant is originally established by skipping all leading whitespace
     * right in the initialization of the class. Later the invariant is maintained
     * by skipping all whitespace after each token whenever a token is read.
     */
    private var position = 0
    
    /** Current line number. Used for [SourceLocation]. */
    private var line = 1
    
    /** Current column number. Used for [SourceLocation]. */
    private var column = 1
    
    private let source: Array<Character>
    private let file: String
    
    /** Lines of the file. Used for [SourceLocation]. */
    private let lines: Array<Substring>
    
    public init(source: String, file: String = "<unknown>") throws {
        self.source = source.unicodeScalars.map { Character(UnicodeScalar($0)) }
        lines = source.lines()
        self.file = file
        try self.skipWhitespace()
    }
    
    /**
     * Does the source contain more tokens?
     */
    public var hasMore: Bool {
        return position < source.count
    }
    
    /**
     * Read the next [Token] from the source, along with its [SourceLocation].
     */
    public func readToken() throws -> TokenInfo {
        let location = currentSourceLocation
        
        let ch = try peekChar()
        
        let token: Token = try {
            
            if (ch.isLetter) { return try readSymbol() }
            else if (ch.isWholeNumber) { return try readNumber() }
            else if (ch == "\"") { return try readString() }
            else if (try readIf(ch: "+")) { return .operator(.plus) }
            else if (try readIf(ch: "-")) { return .operator(.minus) }
            else if (try readIf(ch: "*")) { return .operator(.multiply) }
            else if (try readIf(ch: "/")) { return .operator(.divide) }
            else if (try readIf(ch: "(")) { return .punctuation(.leftParen) }
            else if (try readIf(ch: ")")) { return .punctuation(.rightParen) }
            else if (try readIf(ch: "{")) { return .punctuation(.leftBrace) }
            else if (try readIf(ch: "}")) { return .punctuation(.rightBrace) }
            else if (try readIf(ch: ":")) { return .punctuation(.colon) }
            else if (try readIf(ch: ";")) { return .punctuation(.semicolon) }
            else if (try readIf(ch: ",")) { return .punctuation(.comma) }
            else if (try readIf(ch: "=")) {
                if (try readIf(ch: "=")) {
                    return .operator(.equalEqual)
                }
                else {
                    return .punctuation(.equal)
                }
            }
            else if (try readIf(ch: "!")) {
                if (try readIf(ch: "=")) {
                    return .operator(.notEqual)
                }
                else {
                    return .operator(.not)
                }
            }
            else if (try readIf(ch: "<")) {
                if (try readIf(ch: "=")) {
                    return .operator(.lessThanOrEqual)
                }
                else {
                    return .operator(.lessThan)
                }
            }
            else if (try readIf(ch: ">")) {
                if (try readIf(ch: "=")) {
                    return .operator(.greaterThanOrEqual)
                }
                else {
                    return .operator(.greaterThan)
                }
            }
            else if (try readIf(ch: "&")) {
                if (try readIf(ch: "&")) {
                    return .operator(.and)
                }
                else {
                    throw fail(message: "got '&', did you mean '&&'?")
                }
            }
            else if (try readIf(ch: "|")) {
                if (try readIf(ch: "|")) {
                    return .operator(.or)
                }
                else {
                    throw fail(message: "got '|', did you mean '||'?")
                }
            }
            else {
                throw fail(message: "unexpected character '\(ch)'")
            }
            }()
        
        try skipWhitespace()
        
        return TokenInfo(token: token, location: location)
    }
    
    /**
     * Reads a symbol.
     *
     * Symbols are either [keywords][Token.Keyword], [boolean literals][Token.Literal] or
     * [identifiers][Identifier].
     */
    private func readSymbol() throws -> Token {
        let str = try readWhile { $0.isLetter || $0.isWholeNumber || $0 == "_" }
        switch str {
        case "else":
            return .keyword(.`else`)
        case "fun":
            return .keyword(.fun)
        case "if":
            return .keyword(.if)
        case "var":
            return .keyword(.var)
        case "val":
            return .keyword(.val)
        case "while":
            return .keyword(.while)
        case "true":
            return .literal(value: .bool(value: true))
        case "false":
            return .literal(value: .bool(value: false))
        default:
            return .identifier(name: str)
        }
    }
    
    /**
     * Reads a number literal.
     *
     * Currently only integers are supported.
     */
    private func readNumber() throws -> Token {
        let i = try readWhile { $0.isWholeNumber }
        guard let value = Int(i) else {
            throw fail(message: "expected Int, but got '\(i)'")
        }
        
        return .literal(value: .integer(value: value))
    }
    
    /**
     * Reads a string literal.
     */
    private func readString() throws -> Token {
        var sb = [Character]()
        var escape = false
        
        try expect(ch: "\"")
        
        while (hasMore) {
            let ch = try readChar()
            if (escape) {
                sb.append(ch)
                escape = false
            }
            else if (ch == "\\") {
                escape = true
            }
            else if (ch == "\"") {
                return .literal(value: .string(value: String(sb)))
            }
            else {
                sb.append(ch)
            }
        }
        
        throw unexpectedEnd()
    }
    
    /**
     * Returns the next character in source code without consuming it.
     */
    private func peekChar() throws -> Character {
        if (!hasMore) {
            throw unexpectedEnd()
        }
        return source[position]
    }
    
    /**
     * If next character is [ch], consume the character and return true.
     * Otherwise don't consume the character and return false.
     */
    private func readIf(ch: Character) throws -> Bool {
        if try (hasMore && peekChar() == ch) {
            try readChar()
            return true
        }
        else {
            return false
        }
    }
    
    /**
     * Skip characters in input as long as [predicate] returns `true`.
     */
    private func skipWhile(predicate: (Character) -> Bool) throws {
        while (hasMore && predicate(source[position])) {
            try readChar()
        }
    }
    
    /**
     * Read characters in input as long as [predicate] returns `true`
     * and return the string of read characters.
     */
    private func readWhile(predicate: (Character) -> Bool) throws -> String {
        let start = position
        try skipWhile(predicate: predicate)
        return String(source).substring(startOffset: start, endOffset: position)
    }
    
    /**
     * Reads a single character from source code.
     *
     * This is the only place where [position] may be advanced, because
     * this method takes care of adjusting [line] and [column] accordingly.
     */
    @discardableResult private func readChar() throws -> Character {
        if (!hasMore) {
            throw unexpectedEnd()
        }
        let ch = source[position]
        position += 1
        
        if (ch == "\n") {
            line += 1
            column = 1
        }
        else {
            column += 1
        }
        
        return ch
    }
    
    /**
     * Consume next character if it is [ch]. Otherwise throws [SyntaxErrorException].
     */
    private func expect(ch: Character) throws {
        let c = try peekChar()
        if (ch == c) {
            try readChar()
        }
        else {
            throw fail(message: "expected '\(ch)', but got '\(c)'")
        }
    }
    
    /**
     * Skips all whitespace.
     */
    private func skipWhitespace() throws -> Void {
        try skipWhile { $0.isWhitespace }
    }
    
    /**
     * Returns current source location.
     */
    public var currentSourceLocation : SourceLocation {
        return SourceLocation(file: file, line: line, column: column, lineText: String(lines[line - 1]))
    }
    
    /**
     * Throws [SyntaxErrorException] with given [message] and current [SourceLocation].
     */
    private func fail(message: String) -> SyntaxErrorException {
        return SyntaxErrorException(errorMessage: message, sourceLocation: currentSourceLocation)
    }
    
    /**
     * Throws [UnexpectedEndOfInputException] with current [SourceLocation].
     */
    func unexpectedEnd() -> UnexpectedEndOfInputException {
        return UnexpectedEndOfInputException(sourceLocation: currentSourceLocation)
    }
}

/**
 * Adapts [Lexer] to implement single token lookahead.
 *
 * Parsers generally need to peek one or more tokens ahead before making commitments
 * on what branch to take. Our grammar is simple enough so that we can manage with
 * single token lookahead. We could implement the lookahead either directly in [Lexer]
 * or in our parser, but doing that would needlessly complicate the code there.
 *
 * @param lexer to wrap with lookahead
 */
public class LookaheadLexer {
    let lexer: Lexer
    
    public init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    /**
     * Convenience constructor that creates the wrapped [Lexer] using given [source].
     */
    public convenience init(source: String) throws {
        self.init(lexer: try Lexer(source: source))
    }
    
    /**
     * The lookahead token.
     *
     * If our caller wants to peek a token, we need to read it from [lexer], thus consuming it.
     * However, we'll store it here so that we can pretend that it has not been consumed yet.
     *
     * If we are in sync with [lexer], then the lookahead is `null`,
     */
    var lookahead: TokenInfo? = nil
    
    /**
     * Are there any more tokens in the input?
     */
    public var hasMore: Bool {
        return lookahead != nil || lexer.hasMore
    }
    
    /**
     * Consumes and returns the next token.
     */
    @discardableResult public func readToken() throws -> TokenInfo {
        guard let lookahead = self.lookahead else {
            return try lexer.readToken()
        }
        self.lookahead = nil
        return lookahead
    }
    
    /**
     * Returns the next token without consuming it.
     */
    public func peekToken() throws -> TokenInfo {
        let lookahead: TokenInfo
        if let l = self.lookahead {
            lookahead = l
        }
        else {
            lookahead = try lexer.readToken()
        }
        self.lookahead = lookahead
        return lookahead
    }
    
    /**
     * Returns the location of the next token.
     */
    func nextTokenLocation() throws -> SourceLocation {
        return try peekToken().location
    }
    
    /**
     * Returns true if the next token is [token].
     */
    func nextTokenIs(token: Token) throws -> Bool {
        return try (hasMore && peekToken().token == token)
    }
    
    /**
     * If the next token is [token], consume it and return `true`. Otherwise don't
     * consume the token and return `false`.
     */
    public func readNextIf(token: Token) throws -> Bool {
        if (try nextTokenIs(token: token)) {
            try readToken()
            return true
        }
        else {
            return false
        }
    }
    
    /**
     * If the next token is [expected], consume it and return its location.
     * Otherwise throw [SyntaxErrorException].
     */
    @discardableResult public func expect(expected: Token) throws -> SourceLocation {
        let tokenInfo = try readToken()
        if (tokenInfo.token == expected) {
            return tokenInfo.location
        }
        else {
            throw SyntaxErrorException(errorMessage: "expected token \(expected.description), but got \(tokenInfo.token.description)", sourceLocation: tokenInfo.location)
        }
    }
    
    public var currentSourceLocation : SourceLocation {
        return self.lexer.currentSourceLocation
    }
}
