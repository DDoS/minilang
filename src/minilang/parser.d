module minilang.parser;

import minilang.source;
import minilang.token;
import minilang.lexer;
import minilang.ast;
import minilang.util;

private NameExpr parseName(Lexer tokens) {
    if (tokens.head().kind != TokenKind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = new NameExpr(tokens.head().castOrFail!Identifier());
    tokens.advance();
    return name;
}

private Expression parseAtom(Lexer tokens) {
    switch (tokens.head().kind) with (TokenKind) {
        case IDENTIFIER: {
            return tokens.parseName();
        }
        case LITERAL_STRING: {
            auto token = tokens.head();
            tokens.advance();
            auto literalString = token.castOrFail!LiteralString();
            return new StringExpr(literalString.getValue(), literalString.start, literalString.end);
        }
        case LITERAL_INT: {
            auto token = tokens.head();
            tokens.advance();
            auto literalInt = token.castOrFail!LiteralInt();
            bool overflow = void;
            auto value = literalInt.getValue(overflow);
            if (overflow) {
                throw new SourceException("Integer literal value is out of range", literalInt);
            }
            return new IntExpr(value, literalInt.start, literalInt.end);
        }
        case LITERAL_FLOAT: {
            auto token = tokens.head();
            tokens.advance();
            auto literalFloat = token.castOrFail!LiteralFloat();
            return new FloatExpr(literalFloat.getValue(), literalFloat.start, literalFloat.end);
        }
        case OPERATOR_OPEN_PARENTHESIS: {
            tokens.advance();
            auto expression = parseExpression(tokens);
            if (tokens.head().kind != OPERATOR_CLOSE_PARENTHESIS) {
                throw new SourceException("Expected ')'", tokens.head());
            }
            expression.end = tokens.head().end;
            tokens.advance();
            return expression;
        }
        default: {
            throw new SourceException("Expected a literal, an identifier or '('", tokens.head());
        }
    }
}

private Expression parseUnary(Lexer tokens) {
    if (tokens.head().kind == TokenKind.OPERATOR_MINUS) {
        tokens.advance();
        auto inner = tokens.parseUnary();
        return new NegateExpr(inner);
    }
    return tokens.parseAtom();
}

private template parseBinary(alias parseChild, Binary1, TokenKind kind1, Binary2, TokenKind kind2) {
    private alias parseRecursive = parseBinary!(parseChild, Binary1, kind1, Binary2, kind2);

    private Expression parseBinary(Lexer tokens) {
        auto left = parseChild(tokens);
        return tokens.parseRecursive(left);
    }

    private Expression parseBinary(Lexer tokens, Expression left) {
        switch (tokens.head().kind) with (TokenKind) {
            case kind1: {
                tokens.advance();
                auto right = parseChild(tokens);
                return tokens.parseRecursive(new Binary1(left, right));
            }
            case kind2: {
                tokens.advance();
                auto right = parseChild(tokens);
                return tokens.parseRecursive(new Binary2(left, right));
            }
            default: {
                return left;
            }
        }
    }
}

private alias parseMultiply = parseBinary!(parseUnary,
    MultiplyExpr, TokenKind.OPERATOR_TIMES,
    DivideExpr, TokenKind.OPERATOR_DIVIDE
);

private alias parseAdd = parseBinary!(parseMultiply,
    AddExpr, TokenKind.OPERATOR_PLUS,
    SubtractExpr, TokenKind.OPERATOR_MINUS
);

private alias parseExpression = parseAdd;

private size_t parseSemicolon(Lexer tokens) {
    if (tokens.head().kind != TokenKind.SEMICOLON) {
        throw new SourceException("Expected ';'", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    return end;
}

private Declaration parseDeclaration(Lexer tokens) {
    // Starts with "var"
    if (tokens.head().kind != TokenKind.KEYWORD_VAR) {
        throw new SourceException("Expected \"var\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Followed by an identifier
    if (tokens.head().kind != TokenKind.IDENTIFIER) {
        throw new SourceException("Expected an identifier", tokens.head());
    }
    auto name = tokens.head().castOrFail!Identifier();
    tokens.advance();
    // Followed by ':'
    if (tokens.head().kind != TokenKind.COLON) {
        throw new SourceException("Expected ':'", tokens.head());
    }
    tokens.advance();
    // Followed by a type keyword
    auto typeKeyword = tokens.head();
    tokens.advance();
    Declaration.TypeName typeName = void;
    switch (typeKeyword.kind) with (TokenKind) {
        case KEYWORD_STRING: {
            typeName = new Declaration.TypeName(typeKeyword.castOrFail!KeywordString());
            break;
        }
        case KEYWORD_INT: {
            typeName = new Declaration.TypeName(typeKeyword.castOrFail!KeywordInt());
            break;
        }
        case KEYWORD_FLOAT: {
            typeName = new Declaration.TypeName(typeKeyword.castOrFail!KeywordFloat());
            break;
        }
        default: {
            throw new SourceException("Expected \"string\", \"int\" or \"float\"", typeKeyword);
        }
    }
    // Ends with ';'
    auto end = tokens.parseSemicolon();
    return new Declaration(typeName, name, start, end);
}

private ReadStmt parseReadStatement(Lexer tokens) {
    // Starts with "read"
    if (tokens.head().kind != TokenKind.KEYWORD_READ) {
        throw new SourceException("Expected \"read\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Followed by a name
    auto name = tokens.parseName();
    // Ends with ';'
    auto end = tokens.parseSemicolon();
    return new ReadStmt(name, start, end);
}

private PrintStmt parsePrintStatement(Lexer tokens) {
    // Starts with "print"
    if (tokens.head().kind != TokenKind.KEYWORD_PRINT) {
        throw new SourceException("Expected \"print\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Followed by an expression
    auto value = tokens.parseExpression();
    // Ends with ';'
    auto end = tokens.parseSemicolon();
    return new PrintStmt(value, start, end);
}

private Assignment parseAssignment(Lexer tokens) {
    // Starts with a name
    auto name = tokens.parseName();
    // Followed by '='
    if (tokens.head().kind != TokenKind.OPERATOR_ASSIGN) {
        throw new SourceException("Expected '='", tokens.head());
    }
    tokens.advance();
    // Followed by an expression
    auto value = tokens.parseExpression();
    // Ends with ';'
    auto end = tokens.parseSemicolon();
    return new Assignment(name, value, end);
}

private IfStmt parseIfStatement(Lexer tokens) {
    // Starts with "if"
    if (tokens.head().kind != TokenKind.KEYWORD_IF) {
        throw new SourceException("Expected \"if\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Followed by an expression
    auto condition = tokens.parseExpression();
    // Followed by "then"
    if (tokens.head().kind != TokenKind.KEYWORD_THEN) {
        throw new SourceException("Expected \"then\"", tokens.head());
    }
    tokens.advance();
    // Followed by statements
    auto statements = tokens.parseStatements();
    // Optionally followed by "else"
    IfStmt.Else elseBlock = null;
    if (tokens.head().kind == TokenKind.KEYWORD_ELSE) {
        tokens.advance();
        // Followed by statements
        auto elseStatements = tokens.parseStatements();
        elseBlock = new IfStmt.Else(elseStatements);
    }
    // Ends with "endif"
    if (tokens.head().kind != TokenKind.KEYWORD_ENDIF) {
        throw new SourceException("Expected \"endif\"", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    return new IfStmt(condition, statements, elseBlock, start, end);
}

private WhileStmt parseWhileStatement(Lexer tokens) {
    // Starts with "while"
    if (tokens.head().kind != TokenKind.KEYWORD_WHILE) {
        throw new SourceException("Expected \"while\"", tokens.head());
    }
    auto start = tokens.head().start;
    tokens.advance();
    // Followed by an expression
    auto condition = tokens.parseExpression();
    // Followed by "do"
    if (tokens.head().kind != TokenKind.KEYWORD_DO) {
        throw new SourceException("Expected \"do\"", tokens.head());
    }
    tokens.advance();
    // Followed by statements
    auto statements = tokens.parseStatements();
    // Ends with "done"
    if (tokens.head().kind != TokenKind.KEYWORD_DONE) {
        throw new SourceException("Expected \"done\"", tokens.head());
    }
    auto end = tokens.head().end;
    tokens.advance();
    return new WhileStmt(condition, statements, start, end);
}

private Statement tryParseStatement(Lexer tokens) {
    switch (tokens.head().kind) with (TokenKind) {
        case KEYWORD_READ: {
            return tokens.parseReadStatement();
        }
        case KEYWORD_PRINT: {
            return tokens.parsePrintStatement();
        }
        case IDENTIFIER: {
            return tokens.parseAssignment();
        }
        case KEYWORD_IF: {
            return tokens.parseIfStatement();
        }
        case KEYWORD_WHILE: {
            return tokens.parseWhileStatement();
        }
        default: {
            return null;
        }
    }
}

private Statement[] parseStatements(Lexer tokens) {
    Statement[] statements;
    while (true) {
        auto statement = tokens.tryParseStatement();
        if (statement is null) {
            break;
        }
        statements ~= statement;
    }
    return statements;
}

public Program parseProgram(Lexer tokens) {
    // Starts with declarations
    Declaration[] declarations;
    while (tokens.head().kind == TokenKind.KEYWORD_VAR) {
        declarations ~= tokens.parseDeclaration();
    }
    // Ends with statements
    auto statements = tokens.parseStatements();
    // Make sure there aren't any tokens left
    if (tokens.has()) {
        throw new SourceException("Expected end of program", tokens.head());
    }
    return new Program(declarations, statements);
}
