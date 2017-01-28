module minilang.ast;

import std.conv : to;
import std.format : format;

import minilang.source;
import minilang.token;
import minilang.util;

public abstract class Expression {
    protected this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields;
}

public class NameExpr : Expression {
    private string _name;

    public this(Identifier name) {
        super(name.start, name.end);
        _name = name.getSource();
    }

    @property public string name() {
        return _name;
    }

    public override string toString() {
        return _name;
    }
}

private class LiteralExpr(V) : Expression {
    private V _value;

    public this(V value, size_t start, size_t end) {
        super(start, end);
        _value = value;
    }

    @property public V value() {
        return _value;
    }

    public override string toString() {
        static if (is(V == string)) {
            return format("\"%s\"", _value.escapeString());
        }
        return _value.to!string();
    }
}

public alias StringExpr = LiteralExpr!string;
public alias IntExpr = LiteralExpr!long;
public alias FloatExpr = LiteralExpr!double;

public class NegateExpr : Expression {
    private Expression _inner;

    public this(Expression inner) {
        super(inner.start, inner.end);
        _inner = inner;
    }

    @property public Expression inner() {
        return _inner;
    }

    public override string toString() {
        return format("Negate(%s)", _inner.toString());
    }
}

private class Binary(string name) : Expression {
    private Expression _left;
    private Expression _right;

    public this(Expression left, Expression right) {
        super(left.start, right.end);
        _left = left;
        _right = right;
    }

    @property public Expression left() {
        return _left;
    }

    @property public Expression right() {
        return _right;
    }

    public override string toString() {
        return format(name ~ "(%s, %s)", _left.toString(), _right.toString());
    }
}

public alias AddExpr = Binary!"Add";
public alias SubtractExpr = Binary!"Subtract";
public alias MultiplyExpr = Binary!"Multiply";
public alias DivideExpr = Binary!"Divide";

public class Declaration {
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
        return format("Declaration(%s %s)", _type.to!string().toLowerCase(), _name.getSource());
    }

    public static enum Type {
        INT, FLOAT, STRING
    }
}

public abstract class Statement {
    protected this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    mixin sourceIndexFields;
}

public class ReadStmt : Statement {
    private Identifier _name;

    public this(Identifier name, size_t start, size_t end) {
        super(start, end);
        _name = name;
    }

    @property public Identifier name() {
        return _name;
    }

    public override string toString() {
        return format("Read(%s)", _name.getSource());
    }
}

public class PrintStmt : Statement {
    private Expression _value;

    public this(Expression value, size_t start, size_t end) {
        super(start, end);
        _value = value;
    }

    @property public Expression value() {
        return _value;
    }

    public override string toString() {
        return format("Print(%s)", _value.toString());
    }
}

public class Assignment : Statement {
    private Identifier _name;
    private Expression _value;

    public this(Identifier name, Expression value, size_t end) {
        super(name.start, end);
        _name = name;
        _value = value;
    }

    @property public Identifier name() {
        return _name;
    }

    @property public Expression value() {
        return _value;
    }

    public override string toString() {
        return format("Assign(%s = %s)", _name.getSource(), _value.toString());
    }
}

public class IfStmt : Statement {
    private Expression _condition;
    private Statement[] _statements;
    private Else _elseBlock;

    public this(Expression condition, Statement[] statements, Else elseBlock, size_t start, size_t end) {
        super(start, end);
        _condition = condition;
        _statements = statements;
        _elseBlock = elseBlock;
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

        @property public Statement[] statements() {
            return _statements;
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
        super(start, end);
        _condition = condition;
        _statements = statements;
    }

    @property public Expression condition() {
        return _condition;
    }

    @property public Statement[] statements() {
        return _statements;
    }

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
