module minilang.ast;

import std.conv : to;
import std.format : format;
import std.uni : asLowerCase;

import minilang.source;
import minilang.token;
import minilang.util;

public interface Expression {
    @property public size_t start();
    @property public size_t end();
    @property public void start(size_t start);
    @property public void end(size_t end);
    public string toString();
}

private class TokenExpression(T : Token) : Expression {
    private T token;

    public this(T token) {
        this.token = token;
    }

    @property public override size_t start() {
        return token.start;
    }

    @property public override size_t end() {
        return token.end;
    }

    @property public override void start(size_t start) {
        token.start = start;
    }

    @property public override void end(size_t end) {
        token.end = end;
    }

    public override string toString() {
        return token.getSource();
    }
}

public alias IdentifierExpr = TokenExpression!Identifier;
public alias StringExpr = TokenExpression!LiteralString;
public alias IntExpr = TokenExpression!LiteralInt;
public alias FloatExpr = TokenExpression!LiteralFloat;

public class NegateExpr : Expression {
    private Expression _inner;

    public this(Expression inner) {
        _inner = inner;
        _start = inner.start;
        _end = inner.end;
    }

    @property public Expression inner() {
        return _inner;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Negate(%s)", _inner.toString());
    }
}

private class Binary(string name) : Expression {
    private Expression _left;
    private Expression _right;

    public this(Expression left, Expression right) {
        _left = left;
        _right = right;
        _start = left.start;
        _end = right.end;
    }

    @property public Expression left() {
        return _left;
    }

    @property public Expression right() {
        return _right;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format(name ~ "(%s, %s)", _left.toString(), _right.toString());
    }
}

public alias AddExpr = Binary!"Add";
public alias SubtractExpr = Binary!"Subtract";
public alias MultiplyExpr = Binary!"Multiply";
public alias DivideExpr = Binary!"Divide";

public interface Statement {
    @property public size_t start();
    @property public size_t end();
    @property public void start(size_t start);
    @property public void end(size_t end);
    public string toString();
}

public class Declaration : Statement {
    private Type _type;
    private Identifier _name;

    public this(Type type, Identifier name, size_t start, size_t end) {
        _type = type;
        _name = name;
        _start = start;
        _end = end;
    }

    @property public Type type() {
        return _type;
    }

    @property public Identifier name() {
        return _name;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Declaration(%s %s)", _type.to!string().asLowerCase(), _name.getSource());
    }

    public static enum Type {
        INT, FLOAT, STRING
    }
}

public class ReadStmt : Statement {
    private Identifier _name;

    public this(Identifier name, size_t start, size_t end) {
        _name = name;
        _start = start;
        _end = end;
    }

    @property public Identifier name() {
        return _name;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Read(%s)", _name.getSource());
    }
}

public class PrintStmt : Statement {
    private Expression _value;

    public this(Expression value, size_t start, size_t end) {
        _value = value;
        _start = start;
        _end = end;
    }

    @property public Expression value() {
        return _value;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Print(%s)", _value.toString());
    }
}

public class Assignment : Statement {
    private Identifier _name;
    private Expression _value;

    public this(Identifier name, Expression value, size_t end) {
        _name = name;
        _value = value;
        _start = name.start;
        _end = end;
    }

    @property public Identifier name() {
        return _name;
    }

    @property public Expression value() {
        return _value;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Assign(%s = %s)", _name.getSource(), _value.toString());
    }
}

public class IfStmt : Statement {
    private Expression _condition;
    private Statement[] _statements;
    private Else _elseBlock;

    public this(Expression condition, Statement[] statements, Else elseBlock, size_t start, size_t end) {
        _condition = condition;
        _statements = statements;
        _elseBlock = elseBlock;
        _start = start;
        _end = end;
    }

    @property public Expression condition() {
        return _condition;
    }

    @property public Statement[] statements() {
        return _statements;
    }

    @property public IfStmt.Else elseBlock() {
        return _elseBlock;
    }

    mixin sourceIndexFields;

    public override string toString() {
        auto stmtString = _statements.join!"; "();
        if (_elseBlock !is null) {
            stmtString ~= "; " ~ _elseBlock.toString();
        }
        return format("If(%s: %s)", _condition.toString(), stmtString);
    }

    public static class Else {
        private Statement[] _statements;

        public this(Statement[] statements) {
            _statements = statements;
        }

        public override string toString() {
            return format("Else(%s)", _statements.join!"; "());
        }
    }
}

public class WhileStmt : Statement {
    private Expression _condition;
    private Statement[] _statements;

    public this(Expression condition, Statement[] statements, size_t start, size_t end) {
        _condition = condition;
        _statements = statements;
        _start = start;
        _end = end;
    }

    @property public Expression condition() {
        return _condition;
    }

    @property public Statement[] statements() {
        return _statements;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("While(%s: %s)", _condition.toString(), _statements.join!"; "());
    }
}

public class Program {
    private Declaration[] _declarations;
    private Statement[] _statements;

    public this(Declaration[] declarations, Statement[] statements) {
        _declarations = declarations;
        _statements = statements;

        if (declarations.length > 0) {
            _start = declarations[0].start;
        } else if (statements.length > 0) {
            _start = statements[0].start;
        } else {
            _start = 0;
        }
        if (statements.length > 0) {
            _end = statements[$ - 1].end;
        } else if (declarations.length > 0) {
            _end = declarations[$ - 1].end;
        } else {
            _end = 0;
        }
    }

    @property public Declaration[] declarations() {
        return _declarations;
    }

    @property public Statement[] statements() {
        return _statements;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Program(%s; %s)", _declarations.join!"; "(), _statements.join!"; "());
    }
}
