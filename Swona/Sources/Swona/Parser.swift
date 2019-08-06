

/**
 * Parse [code] as [Expression].
 *
 * @throws SyntaxErrorException if parsing fails
 */
public func parseExpression(code: String) throws -> Expression  {
    return try parseComplete(lexer: try Lexer(source: code)) { try $0.parseTopLevelExpression() }
}

/**
 * Parses a function definition.
 */
public func parseFunctionDefinition(code: String) throws -> FunctionDefinition {
    return try parseComplete(lexer: Lexer(source: code)) { try $0.parseFunctionDefinition() }
}

/**
 * Parses a function definition.
 */
public func parseFunctionDefinitions(code: String, file: String) throws -> [FunctionDefinition] {
    return try parseComplete(lexer: Lexer(source: code, file: file)) { try $0.parseFunctionDefinitions() }
}

/**
 * Executes parser on code and verifies that it consumes all input.
 *
 * @throws SyntaxErrorException if the parser fails or if it did not consume all input
 */
private func parseComplete<T>(lexer: Lexer, callback: (Parser) throws -> T) throws -> T {
    let parser = Parser(lexer: lexer)
    let result = try callback(parser)
    try parser.expectEnd()
    return result
}

/**
 * A simple recursive descent parser.
 */
public class Parser {
    private let lexer: LookaheadLexer;

    init(lexer: Lexer) {
        self.lexer = LookaheadLexer(lexer: lexer)
    }

    func parseFunctionDefinitions() throws -> Array<FunctionDefinition> {
        var result = Array<FunctionDefinition>()

        while (lexer.hasMore) {
            result += [try parseFunctionDefinition()]
        }

        return result
    }

    /**
     * ```
     * functionDefinition :== "fun" name "(" args ")" [ ":" type ] "=" expression
     * ```
     */
    func parseFunctionDefinition() throws -> FunctionDefinition {
        try lexer.expect(expected: .keyword(.fun))
        let name = try parseName().0
        let args = try parseArgumentDefinitionList()
        let returnType: Type?;
        if (try lexer.readNextIf(token: .punctuation(.colon))) {
            returnType = try parseType()
        }
        else {
            returnType = nil
        }
        try lexer.expect(expected: .punctuation(.equal))
        let body = try parseTopLevelExpression()

        return FunctionDefinition(name: name, args: args, returnType: returnType, body: body)
    }

    /**
     * Parses an expression.
     *
     * Expression parsers are separated to different levels to handle precedence
     * of operators correctly. The lower levels bind more tightly that the higher
     * levels.
     * ```
     * topLevelExpr ::= | var | '{' exps '}' | ident "=" expression | expression
     * ```
     */
    func parseTopLevelExpression() throws -> Expression {
        switch try lexer.peekToken().token  {
        case let .keyword(keyword):
            switch keyword {
            case .var:
                return try parseVariableDefinition()
            case .val:
                return try parseVariableDefinition()
            default:
                break
            }
        case let .punctuation(punctuation):
            switch punctuation {
            case .leftBrace:
                return try parseExpressionList()
            default:
                break
            }
        case .identifier:
            let exp = try parseExpression1()
            if case let .ref(name, _) = exp, try lexer.nextTokenIs(token: .punctuation(.equal)) {
                return try parseAssignTo(variable: name)
            }
            else {
                return exp
            }

        default:
            break
        }

        return try parseExpression1()
    }

    /**
     * ```
     * expression1 ::= expression2 (("||") expression2)
     * ```
     */
    private func parseExpression1() throws -> Expression {
        var exp = try parseExpression2()

        while (lexer.hasMore) {
            let location = try lexer.nextTokenLocation()
            if (try lexer.readNextIf(token: .operator(.or))) {
                exp = Expression.binary(.or(lhs: exp, rhs: try parseExpression2(), location: location))
            }
            else {
                return exp
            }
        }
        return exp
    }

    /**
     * ```
     * expression2 ::= expression3 (("&&") expression2)
     * ```
     */
    private func parseExpression2() throws -> Expression {
        var exp = try parseExpression3()

        while (lexer.hasMore) {
            let location = try lexer.nextTokenLocation()
            if (try lexer.readNextIf(token: .operator(.and))) {
                exp = Expression.binary(.and(lhs: exp, rhs: try parseExpression3(), location: location))
            }
            else {
                return exp
            }
        }

        return exp
    }

    /**
     * ```
     * expression3 ::= expression4 (("==" | "!=") expression4)*
     * ```
     */
    func parseExpression3() throws -> Expression {
        var exp = try parseExpression4()

        while (lexer.hasMore) {
            let location = try lexer.nextTokenLocation()
            if (try lexer.readNextIf(token: .operator(.equalEqual))) {
                exp = Expression.binary(.relational(op: .equals, lhs: exp, rhs: try parseExpression4(), location: location))
            }
            else if (try lexer.readNextIf(token: .operator(.notEqual))) {
                exp = Expression.binary(.relational(op: .notEquals, lhs: exp, rhs: try parseExpression4(), location: location))
            }
            else {
                return exp
            }
        }

        return exp
    }

    /**
     * ```
     * expression4 ::= expression5 (("<" | ">" | "<=" | ">=") expression5)*
     * ```
     */
    private func parseExpression4() throws -> Expression {
        var exp = try parseExpression5()

        while (lexer.hasMore) {
            let location = try lexer.nextTokenLocation()
            if (try lexer.readNextIf(token: .`operator`(.lessThan))) {
                exp = Expression.binary(.relational(op: .lessThan, lhs: exp, rhs: try parseExpression5(), location: location))
            }
            else if (try lexer.readNextIf(token: .`operator`(.lessThanOrEqual))) {
                exp = Expression.binary(.relational(op: .lessThanOrEqual, lhs: exp, rhs: try parseExpression5(), location: location))
            }
            else if (try lexer.readNextIf(token: .`operator`(.greaterThan))) {
                exp = Expression.binary(.relational(op: .greaterThan, lhs: exp, rhs: try parseExpression5(), location: location))
            }
            else if (try lexer.readNextIf(token: .`operator`(.greaterThanOrEqual))) {
                exp = Expression.binary(.relational(op: .greaterThanOrEqual, lhs: exp, rhs: try parseExpression5(), location: location))
            }
            else {
                return exp
            }
        }

        return exp
    }

    /**
     * ```
     * expression5 ::= expression6 (("+" | "-") expression6)*
     * ```
     */
    private func parseExpression5() throws -> Expression {
        var exp = try parseExpression6()

        while (lexer.hasMore) {
            let location = try lexer.nextTokenLocation()
            if (try lexer.readNextIf(token: .operator(.plus))) {
                exp = Expression.binary(.plus(lhs: exp, rhs: try parseExpression6(), location: location))
            }
            else if (try lexer.readNextIf(token: .operator(.minus))) {
                exp = Expression.binary(.minus(lhs: exp, rhs: try parseExpression6(), location: location))
            }
            else {
                return exp
            }
        }

        return exp
    }

    /**
     * ```
     * expression6 ::= expression7 (("*" | "/") expression7)
     * ```
     */
    private func parseExpression6() throws -> Expression {
        var exp = try parseExpression7()

        while (lexer.hasMore) {
            let location = try lexer.nextTokenLocation()
            if (try lexer.readNextIf(token: .operator(.multiply))) {
                exp = Expression.binary(.multiply(lhs: exp, rhs: try parseExpression7(), location: location))
            }
            else if (try lexer.readNextIf(token: .operator(.divide))) {
                exp = Expression.binary(.divide(lhs: exp, rhs: try parseExpression7(), location: location))
            }
            else {
                return exp
            }
        }

        return exp
    }

    /**
     * ```
     * expression7 ::= expression8 [ '(' args ')']
     * ```
     */
    private func parseExpression7() throws -> Expression {
        let exp = try parseExpression8()

        if try lexer.nextTokenIs(token: .punctuation(.leftParen)) {
            return Expression.call(func: exp, args: try parseArgumentList())
        }
        else {
            return exp
        }
    }

    /**
     * ```
     * expression8 ::= identifier | literal | not | "(" expression ")" | if | while
     * ```
     */
    private func parseExpression8() throws -> Expression {
        let tokenInfo = try lexer.peekToken()
        switch tokenInfo.token {
        case .identifier:
            return try parseIdentifier()
        case .literal:
            return try parseLiteral()
        case let .operator(`operator`):
            switch `operator` {
            case .not:
                return try parseNot()
            default:
                break
            }
        case let .punctuation(punctuation):
            switch punctuation {
            case .leftParen:
                return try inParens { try parseTopLevelExpression() }
            default:
                break
            }
        case let .keyword(`keyword`):
            switch `keyword` {
            case .if:
                return try parseIf()
            case .unless:
                return try parseUnless()
            case .while:
                return try parseWhile()
            default:
                break
            }
        }
        throw fail(location: tokenInfo.location, message: "unexpected token \(tokenInfo.token.description)")
    }

    private func parseAssignTo(variable: String) throws -> Expression {
        let location = try lexer.expect(expected: .punctuation(.equal))
        let rhs = try parseTopLevelExpression()

        return Expression.assign(variable: variable, expression: rhs, location: location)
    }

    private func parseVariableDefinition() throws -> Expression {
        let mutable = try lexer.nextTokenIs(token: .keyword(.var))
        let location: SourceLocation
        if mutable {
            location = try lexer.expect(expected: .keyword(.var))
        }
        else {
            location = try lexer.expect(expected: .keyword(.val))
        }

        let variable = try parseName().0
        try lexer.expect(expected: .punctuation(.equal))
        let expression = try parseTopLevelExpression()
        return Expression.`var`(variable: variable, expression: expression, mutable: mutable, location: location)
    }

    private func parseIf() throws -> Expression {
        let location = try lexer.expect(expected: .keyword(.if))
        let condition = try inParens { try parseTopLevelExpression() }
        let consequent = try parseTopLevelExpression()
        let alternative: Expression?
        if try lexer.readNextIf(token: .keyword(.else)) {
            alternative = try parseTopLevelExpression()
        }
        else {
            alternative = nil
        }

        return Expression.`if`(condition: condition, consequent: consequent, alternative: alternative, location: location)
    }

    private func parseUnless() throws -> Expression {
        let location = try lexer.expect(expected: .keyword(.unless))
        let condition = try inParens { try parseTopLevelExpression() }
        let consequent = try parseTopLevelExpression()
        let alternative: Expression?
        if try lexer.readNextIf(token: .keyword(.else)) {
            alternative = try parseTopLevelExpression()
        }
        else {
            alternative = nil
        }

        return Expression.`if`(condition: .not(exp: condition, location: location), consequent: consequent, alternative: alternative, location: location)
    }


    private func parseWhile() throws -> Expression {
        let location = try lexer.expect(expected: .keyword(.while))
        let condition = try inParens { try parseTopLevelExpression() }
        let body = try parseTopLevelExpression()

        return Expression.`while`(condition: condition, body: body, location: location)
    }

    private func parseExpressionList() throws -> Expression {
        let location = try lexer.nextTokenLocation()
        let result: [Expression] = try inBraces {
            if (try lexer.nextTokenIs(token: .punctuation(.rightBrace))) {
                return []
            }
            else {
                return try separatedBy(separator: .punctuation(.semicolon)) { try parseTopLevelExpression() }
            }
        }

        return Expression.`expressionList`(expressions: result, location: location)
    }

    private func parseLiteral() throws -> Expression {
        let tokenInfo = try lexer.readToken()
        guard case let Token.literal(value) = tokenInfo.token else {
            throw SyntaxErrorException(errorMessage: "expected token of type Token.identifier, but got \(tokenInfo.token.description)", sourceLocation: tokenInfo.location)
        }
        return Expression.lit(value: value, location: tokenInfo.location)
    }

    private func parseNot() throws -> Expression {
        let location = try lexer.expect(expected: .operator(.not))
        let exp = try parseExpression7()

        return Expression.not(exp: exp, location: location)
    }

    private func parseIdentifier() throws -> Expression {
        let (name, location) = try parseName()

        return Expression.ref(name: name, location: location)
    }

    private func parseArgumentList() throws -> Array<Expression>  {
        return try inParens {
            if (try lexer.nextTokenIs(token: .punctuation(.rightParen))) {
                return []
            }
            else {
                var args = Array<Expression>()
                repeat {
                    args.append(try parseTopLevelExpression())
                } while (try lexer.readNextIf(token: .punctuation(.comma)))
                return args
            }
        }
    }

    private func parseArgumentDefinitionList() throws -> Array<(String, Type)> {
        return try inParens {
            if (try lexer.nextTokenIs(token: .punctuation(.rightParen))) {
                return []
            }
            else {
                var args = Array<(String, Type)>()
                repeat {
                    let name = try parseName().0
                    try lexer.expect(expected: .punctuation(.colon))
                    let type = try parseType()
                    args.append((name, type))
                } while try (lexer.readNextIf(token: .punctuation(.comma)))
                return args
            }
        }
    }

    private func parseName() throws -> (String, SourceLocation) {
        let tokenInfo = try lexer.readToken()
        guard case let Token.identifier(name) = tokenInfo.token else {
            throw SyntaxErrorException(errorMessage: "expected token of type Token.identifier, but got \(tokenInfo.token.description)", sourceLocation: tokenInfo.location)
        }
        return (name, tokenInfo.location)
    }

    private func parseType() throws -> Type {
        let tokenInfo = try lexer.readToken()
        guard case let Token.identifier(name) = tokenInfo.token else {
            throw SyntaxErrorException(errorMessage: "expected token of type Token.identifier, but got \(tokenInfo.token.description)", sourceLocation: tokenInfo.location)
        }
        switch name {
        case "Unit":
            return Type.unit
        case "Boolean":
            return Type.boolean
        case "Int":
            return Type.int
        case "String":
            return Type.string
        default:
            throw fail(location: tokenInfo.location, message: "unknown type name: '\(name)'")
        }
    }

    private func inParens<T>(parser: () throws -> T) throws -> T {
        return try between(left: .punctuation(.leftParen), right: .punctuation(.rightParen), parser: parser)
    }

    private func inBraces<T>(parser: () throws -> T) throws -> T {
        return try between(left: .punctuation(.leftBrace), right: .punctuation(.rightBrace), parser: parser)
    }

    private func between<T>(left: Token, right: Token, parser: () throws -> T) throws -> T {
        try lexer.expect(expected: left)
        let value = try parser()
        try lexer.expect(expected: right)
        return value
    }

    private func separatedBy<T> (separator: Token, parser: () throws -> T) throws -> Array<T> {
        var result = Array<T>()

        repeat {
            try result.append(parser())
        } while (try lexer.readNextIf(token: separator))

        return result
    }

    private func fail(message: String) -> SyntaxErrorException {
        return fail(location: self.lexer.currentSourceLocation, message: message)
    }

    private func fail(location: SourceLocation, message: String) -> SyntaxErrorException {
        return SyntaxErrorException(errorMessage: message, sourceLocation: location)
    }

    func expectEnd() throws {
        if (lexer.hasMore) {
            let tokenInfo = try lexer.peekToken()
            throw fail(location: tokenInfo.location, message: "expected end, but got \(tokenInfo.token)")
        }
    }
}
