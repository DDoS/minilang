module minilang.chars;

import std.format : format;
import std.uni : isGraphical;
import std.conv : to;

private enum char[char] CHAR_ESCAPES = [
    '\t': 't',
    '\n': 'n',
    '\r': 'r'
];

public bool isIdentifierStart(char c) {
    return c == '_' || c.isLetter();
}

public bool isIdentifierBody(char c) {
    return c.isIdentifierStart() || c.isDecimalDigit();
}

public bool isLetter(char c) {
    return c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z';
}

public bool isDecimalDigit(char c) {
    return c >= '0' && c <= '9';
}

public bool isNewLineChar(char c) {
    return c == '\n' || c == '\r';
}

public bool isLineWhiteSpace(char c) {
    return c == ' ' || c == '\t';
}

public bool isWhiteSpace(char c) {
    return c.isNewLineChar() || c.isLineWhiteSpace();
}

public string escapeChar(char c) {
    auto escape = c in CHAR_ESCAPES;
    if (escape !is null) {
        return "\\" ~ (*escape).to!string();
    }
    if (c.isGraphical()) {
        return c.to!string();
    }
    return format("\\u%02X", c).to!string();
}
