module minilang.chars;

import std.format : format;
import std.conv : to;

import minilang.util;

private enum char[char] CHAR_TO_ESCAPE = [
    'a': '\a',
    'b': '\b',
    't': '\t',
    'n': '\n',
    'v': '\v',
    'f': '\f',
    'r': '\r',
    '"': '"',
    '\\': '\\'
];
private enum char[char] ESCAPE_TO_CHAR = CHAR_TO_ESCAPE.inverse();

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

public bool isNewLine(char c) {
    return c == '\n' || c == '\r';
}

public bool isLineWhiteSpace(char c) {
    return c == ' ' || c == '\t';
}

public bool isWhiteSpace(char c) {
    return c.isNewLine() || c.isLineWhiteSpace();
}

public bool isPrintable(char c) {
    return c >= ' ' && c <= '~' || c == '\t';
}

public bool isEscapeChar(char c) {
    return (c in CHAR_TO_ESCAPE) !is null;
}

public char decodeCharEscape(char c) {
    auto optChar = c in CHAR_TO_ESCAPE;
    if (optChar is null) {
        throw new Error(format("Not a valid escape character: %s", c.escapeChar()));
    }
    return *optChar;
}

public string escapeChar(char c) {
    auto optEscape = c in ESCAPE_TO_CHAR;
    if (optEscape !is null) {
        return "\\" ~ (*optEscape).to!string();
    }
    if (c.isPrintable()) {
        return c.to!string();
    }
    if (c == '\u0004') {
        return "EOF";
    }
    return format("0x%02X", c).to!string();
}
