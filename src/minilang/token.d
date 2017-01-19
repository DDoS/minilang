module minilang.token;

import std.format : format;
import std.conv : to, ConvOverflowException;

import minilang.chars;
import minilang.source;

public enum TokenKind {
    COLON,
    SEMICOLON,

    IDENTIFIER,

    KEYWORD_VAR,
    KEYWORD_DONE,
    KEYWORD_ELSE,
    KEYWORD_FLOAT,
    KEYWORD_PRINT,
    KEYWORD_WHILE,
    KEYWORD_IF,
    KEYWORD_ENDIF,
    KEYWORD_INT,
    KEYWORD_READ,
    KEYWORD_DO,
    KEYWORD_THEN,
    KEYWORD_STRING,

    OPERATOR_PLUS,
    OPERATOR_MINUS,
    OPERATOR_TIMES,
    OPERATOR_DIVIDE,
    OPERATOR_ASSIGN,
    OPERATOR_OPEN_PARENTHESIS,
    OPERATOR_CLOSE_PARENTHESIS,

    LITERAL_INT,
    LITERAL_FLOAT,
    LITERAL_STRING,

    EOF
}

public interface Token {
    @property public size_t start();
    @property public size_t end();
    @property public void start(size_t start);
    @property public void end(size_t end);
    public string getSource();
    public TokenKind kind();
    public string toString();
}

private template FixedToken(TokenKind _kind, string source) if (source.length > 0) {
    private class FixedToken : Token {
        public this(size_t start) {
            _start = start;
            _end = start + source.length - 1;
        }

        public override string getSource() {
            return source;
        }

        @property public override TokenKind kind() {
            return _kind;
        }

        mixin sourceIndexFields;

        public override string toString() {
            return _kind.to!string();
        }
    }
}

public alias Colon = FixedToken!(TokenKind.COLON, ":");
public alias Semicolon = FixedToken!(TokenKind.SEMICOLON, ";");

public alias KeywordVar = FixedToken!(TokenKind.KEYWORD_VAR, "var");
public alias KeywordDone = FixedToken!(TokenKind.KEYWORD_DONE, "done");
public alias KeywordElse = FixedToken!(TokenKind.KEYWORD_ELSE, "else");
public alias KeywordFloat = FixedToken!(TokenKind.KEYWORD_FLOAT, "float");
public alias KeywordPrint = FixedToken!(TokenKind.KEYWORD_PRINT, "print");
public alias KeywordWhile = FixedToken!(TokenKind.KEYWORD_WHILE, "while");
public alias KeywordIf = FixedToken!(TokenKind.KEYWORD_IF, "if");
public alias KeywordEndif = FixedToken!(TokenKind.KEYWORD_ENDIF, "endif");
public alias KeywordInt = FixedToken!(TokenKind.KEYWORD_INT, "int");
public alias KeywordRead = FixedToken!(TokenKind.KEYWORD_READ, "read");
public alias KeywordDo = FixedToken!(TokenKind.KEYWORD_DO, "do");
public alias KeywordThen = FixedToken!(TokenKind.KEYWORD_THEN, "then");
public alias KeywordString = FixedToken!(TokenKind.KEYWORD_STRING, "string");

public alias OperatorPlus = FixedToken!(TokenKind.OPERATOR_PLUS, "+");
public alias OperatorMinus = FixedToken!(TokenKind.OPERATOR_MINUS, "-");
public alias OperatorTimes = FixedToken!(TokenKind.OPERATOR_TIMES, "*");
public alias OperatorDivide = FixedToken!(TokenKind.OPERATOR_DIVIDE, "/");
public alias OperatorAssign = FixedToken!(TokenKind.OPERATOR_ASSIGN, "=");
public alias OperatorOpenParenthesis = FixedToken!(TokenKind.OPERATOR_OPEN_PARENTHESIS, "(");
public alias OperatorCloseParenthesis = FixedToken!(TokenKind.OPERATOR_CLOSE_PARENTHESIS, ")");

public class Identifier : Token {
    private string source;

    public this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    public override string getSource() {
        return source;
    }

    @property public override TokenKind kind() {
        return TokenKind.IDENTIFIER;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("%s(%s)", kind, source);
    }
}

public class LiteralString : Token {
    private string source;

    public this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    public override string getSource() {
        return source;
    }

    @property public override TokenKind kind() {
        return TokenKind.LITERAL_STRING;
    }

    mixin sourceIndexFields;

    public string getValue() {
        auto length = source.length;
        if (length < 2) {
            throw new Error("String is missing enclosing quotes");
        }
        if (source[0] != '"') {
            throw new Error("String is missing beginning quote");
        }
        auto value = source[1 .. length - 1].decodeStringContent();
        if (source[length - 1] != '"') {
            throw new Error("String is missing ending quote");
        }
        return value;
    }

    public override string toString() {
        return format("%s(%s)", kind, source);
    }

    unittest {
        auto a = new LiteralString("\"hel\\\"lo\"", 0);
        assert(a.getValue() == "hel\"lo");
        auto b = new LiteralString("\"hel\\\\lo\"", 0);
        assert(b.getValue() == "hel\\lo");
        auto c = new LiteralString("\"hel\\nlo\"", 0);
        assert(c.getValue() == "hel\nlo");
        auto d = new LiteralString("\"hel\\r\\f\\vlo\"", 0);
        assert(d.getValue() == "hel\r\f\vlo");
    }
}

private string decodeStringContent(string data) {
    char[] buffer = [];
    buffer.reserve(64);
    for (size_t i = 0; i < data.length; ) {
        char c = data[i];
        i += 1;
        if (c == '\\') {
            c = data[i];
            i += 1;
            c = c.decodeCharEscape();
        }
        buffer ~= c;
    }
    return buffer.idup;
}

public class LiteralInt : Token {
    private string source;

    public this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    public override string getSource() {
        return source;
    }

    @property public override TokenKind kind() {
        return TokenKind.LITERAL_INT;
    }

    mixin sourceIndexFields;

    public long getValue(out bool overflow) {
        try {
            overflow = false;
            return source.to!long(10);
        } catch (ConvOverflowException) {
            overflow = true;
            return -1;
        }
    }

    public override string toString() {
        return format("%s(%s)", kind, source);
    }

    unittest {
        bool overflow;
        auto a = new LiteralInt("42432", 0);
        assert(a.getValue(overflow) == 42432);
        assert(!overflow);
        auto b = new LiteralInt("9223372036854775808", 0);
        b.getValue(overflow);
        assert(overflow);
    }
}

public class LiteralFloat : Token {
    private string source;

    public this(string source, size_t start) {
        this.source = source;
        _start = start;
        _end = start + source.length - 1;
    }

    public override string getSource() {
        return source;
    }

    @property public override TokenKind kind() {
        return TokenKind.LITERAL_FLOAT;
    }

    mixin sourceIndexFields;

    public double getValue() {
        return source.to!double();
    }

    public override string toString() {
        return format("%s(%s)", kind, source);
    }

    unittest {
        auto a = new LiteralFloat("62.33352", 0);
        assert(a.getValue() == 62.33352);
        auto b = new LiteralFloat("1.1", 0);
        assert(b.getValue() == 1.1);
        auto c = new LiteralFloat("0.1", 0);
        assert(c.getValue() == 0.1);
    }
}

public class Eof : Token {
    public this(size_t index) {
        _start = index;
        _end = index;
    }

    public override string getSource() {
        return "\u0004";
    }

    @property public TokenKind kind() {
        return TokenKind.EOF;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return "EOF()";
    }
}

public alias FixedTokenCtor = Token function(size_t);

private enum FixedTokenCtor[string] KEYWORD_CTOR_MAP = buildFixedTokenCtorMap!(
    KeywordVar, KeywordDone, KeywordElse, KeywordFloat, KeywordPrint, KeywordWhile, KeywordIf,
    KeywordEndif, KeywordInt, KeywordRead, KeywordDo, KeywordThen, KeywordString
);

private enum FixedTokenCtor[string] OPERATOR_CTOR_MAP = buildFixedTokenCtorMap!(
    OperatorPlus, OperatorMinus, OperatorTimes, OperatorDivide, OperatorAssign,
    OperatorOpenParenthesis, OperatorCloseParenthesis
);

private FixedTokenCtor[string] buildFixedTokenCtorMap(Token, Tokens...)() {
    static if (is(Token == FixedToken!(kind, source), TokenKind kind, string source)) {
        static if (Tokens.length > 0) {
            auto map = buildFixedTokenCtorMap!Tokens();
        } else {
            FixedTokenCtor[string] map;
        }
        map[source] = (size_t start) => new Token(start);
        return map;
    } else {
        static assert (0);
    }
}

public bool isKeyword(string identifier) {
    return (identifier in KEYWORD_CTOR_MAP) !is null;
}

public Token createKeyword(string source, size_t start) {
    return KEYWORD_CTOR_MAP[source](start);
}

public bool isOperator(char c) {
    return (c.to!string() in OPERATOR_CTOR_MAP) !is null;
}

public Token createOperator(char source, size_t start) {
    return OPERATOR_CTOR_MAP[source.to!string()](start);
}
