module minilang.lexer;

import minilang.chars;
import minilang.source;
import minilang.token;

public class Lexer {
    private SourceReader reader;
    private Token[] headTokens;
    private size_t position = 0;
    private size_t[] savedPositions;

    public this(SourceReader reader) {
        this.reader = reader;
        headTokens.reserve(32);
        savedPositions.reserve(32);
    }

    public bool has() {
        return head().getKind() != TokenKind.EOF;
    }

    public Token head() {
        while (headTokens.length <= position) {
            headTokens ~= next();
        }
        return headTokens[position];
    }

    public void advance() {
        if (head().getKind() != TokenKind.EOF) {
            position++;
        }
    }

    public void savePosition() {
        savedPositions ~= position;
    }

    public void restorePosition() {
        position = savedPositions[$ - 1];
        discardPosition();
    }

    public void discardPosition() {
        savedPositions.length--;
    }

    public Token next() {
        Token token = null;
        while (reader.has() && token is null) {
            while (reader.head().isWhiteSpace()) {
                // Remove whitespace
                reader.advance();
            }
            if (reader.head() == ';') {
                // Semicolon
                reader.advance();
                token = new Semicolon(reader.count - 1);
            } else if (reader.head().isIdentifierStart()) {
                // Identifier or keyword
                auto position = reader.count;
                reader.collect();
                auto identifier = reader.collectIdentifierBody();
                if (identifier.isKeyword()) {
                    token = identifier.createKeyword(position);
                } else {
                    token = new Identifier(identifier, position);
                }
            } else if (reader.head().isOperator()) {
                // Operator or line comment
                auto position = reader.count;
                auto operator = reader.head();
                reader.advance();
                if (operator == '/' && reader.head() == '/') {
                    reader.advance();
                    reader.consumeLineCommentText();
                } else {
                    token = operator.createOperator(position);
                }
            } else if (reader.head() == '"') {
                auto position = reader.count;
                token = new LiteralString(reader.collectLiteralString(), position);
            } else if (reader.head().isDecimalDigit()) {
                token = reader.collectLiteralNumber();
            } else {
                throw new SourceException("Unexpected character", reader.head(), reader.count);
            }
        }
        return token is null ? new Eof(reader.count) : token;
    }
}

private string collectIdentifierBody(SourceReader reader) {
    while (reader.head().isIdentifierBody()) {
        reader.collect();
    }
    return reader.popCollected();
}

private void consumeLineCommentText(SourceReader reader) {
    while (!reader.head().isNewLineChar()) {
        reader.advance();
    }
    reader.consumeNewLine();
}

private void consumeNewLine(SourceReader reader) {
    if (reader.head() == '\r') {
        // CR
        reader.advance();
        if (reader.head() == '\n') {
            // CR LF
            reader.advance();
        }
    } else if (reader.head() == '\n') {
        // LF
        reader.advance();
    }
}

private string collectLiteralString(SourceReader reader) {
    // Opening "
    if (reader.head() != '"') {
        throw new SourceException("Expected opening \"", reader.head(), reader.count);
    }
    reader.collect();
    // String contents
    auto ignoreNextQuote = false;
    while (ignoreNextQuote || reader.head() != '"') {
        ignoreNextQuote = reader.head() == '\\';
        reader.collect();
    }
    // Closing "
    if (reader.head() != '"') {
        throw new SourceException("Expected closing \"", reader.head(), reader.count);
    }
    reader.collect();
    return reader.popCollected();
}

private Token collectLiteralNumber(SourceReader reader) {
    auto position = reader.count;
    if (reader.head() == '0') {
        reader.collect();
        // Shoulde be just a zero
        if (reader.head().isDecimalDigit()) {
            throw new SourceException("Cannot have 0 as a leading digit", reader.head(), reader.count);
        }
        return new LiteralInt(reader.popCollected(), position);
    }
    // The number must have a decimal digit sequence first
    reader.collectDigitSequence();
    // Now we can have a decimal separator here, making it a float
    if (reader.head() == '.') {
        reader.collect();
        // There needs to be more digits after the decimal separator
        if (!reader.head().isDecimalDigit()) {
            throw new SourceException("Expected more digits afer the decimal point", reader.head(), reader.count);
        }
        reader.collectDigitSequence();
        return new LiteralFloat(reader.popCollected(), position);
    }
    // Else it's a decimal integer and there's nothing more to do
    return new LiteralInt(reader.popCollected(), position);
}


private void collectDigitSequence(SourceReader reader) {
    if (!reader.head().isDecimalDigit()) {
        throw new SourceException("Expected a digit", reader.head(), reader.count);
    }
    reader.collect();
    while (reader.head().isDecimalDigit()) {
        reader.collect();
    }
}
