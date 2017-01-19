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
        return head().kind != TokenKind.EOF;
    }

    public Token head() {
        while (headTokens.length <= position) {
            headTokens ~= next();
        }
        return headTokens[position];
    }

    public void advance() {
        if (head().kind != TokenKind.EOF) {
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

    private Token next() {
        while (reader.has()) {
            if (reader.head().isWhiteSpace()) {
                // Remove whitespace
                reader.advance();
                continue;
            }
            if (reader.head() == ':') {
                // Colon
                reader.advance();
                return new Colon(reader.count - 1);
            }
            if (reader.head() == ';') {
                // Semicolon
                reader.advance();
                return new Semicolon(reader.count - 1);
            }
            if (reader.head().isIdentifierStart()) {
                // Identifier or keyword
                auto position = reader.count;
                reader.collect();
                auto identifier = reader.collectIdentifierBody();
                if (identifier.isKeyword()) {
                    return identifier.createKeyword(position);
                }
                return new Identifier(identifier, position);
            }
            if (reader.head().isOperator()) {
                // Operator or line comment
                auto position = reader.count;
                auto operator = reader.head();
                reader.advance();
                if (operator == '/' && reader.head() == '/') {
                    reader.advance();
                    reader.consumeLineCommentText();
                    continue;
                }
                return operator.createOperator(position);
            }
            if (reader.head() == '"') {
                // String literal
                auto position = reader.count;
                return new LiteralString(reader.collectLiteralString(), position);
            }
            if (reader.head().isDecimalDigit()) {
                // Int or float literal
                return reader.collectLiteralNumber();
            }
            // Unknown
            throw new SourceException("Unexpected character", reader.head(), reader.count);
        }
        // End of file
        return new Eof(reader.count);
    }
}

private string collectIdentifierBody(SourceReader reader) {
    while (reader.head().isIdentifierBody()) {
        reader.collect();
    }
    return reader.popCollected();
}

private void consumeLineCommentText(SourceReader reader) {
    while (reader.has() && !reader.head().isNewLine()) {
        reader.advance();
    }
    if (reader.has()) {
        reader.consumeNewLine();
    }
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
    while (true) {
        if (reader.head().isPrintable() && reader.head() != '"' && reader.head() != '\\') {
            // Collect a normal print character with no special meaning in a string
            reader.collect();
        } else if (reader.collectEscapeSequence()) {
            // Nothing to do, it is already collected by the "if" call
        } else {
            // Not part of a string literal body, end here
            break;
        }
    }
    // Closing "
    if (reader.head() != '"') {
        throw new SourceException("Expected closing \"", reader.head(), reader.count);
    }
    reader.collect();
    return reader.popCollected();
}

private bool collectEscapeSequence(SourceReader reader) {
    if (reader.head() != '\\') {
        return false;
    }
    reader.collect();
    if (!reader.head().isEscapeChar()) {
        throw new SourceException("Not a valid escape sequence", reader.head(), reader.count);
    }
    reader.collect();
    return true;
}

private Token collectLiteralNumber(SourceReader reader) {
    auto position = reader.count;
    // The number must have a decimal digit sequence first
    if (reader.head() == '0') {
        reader.collect();
        // If it starts with zero it should just be a zero
        if (reader.head().isDecimalDigit()) {
            throw new SourceException("Cannot have 0 as a leading digit", reader.head(), reader.count);
        }
        // Check for a decimal separator, which makes it a float
        if (reader.head() != '.') {
            // Else it's just the 0 literal
            return new LiteralInt(reader.popCollected(), position);
        }
    } else {
        // Normal digit sequence not starting with a zero
        reader.collectDigitSequence();
    }
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
