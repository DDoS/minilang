module minilang.ast;

import std.conv : to;
import std.format : format;
import std.typecons : Nullable;

import minilang.source;
import minilang.token;
import minilang.util;

public enum Type {
    INT, FLOAT, STRING
}

public abstract class Expression {
    private Nullable!Type _type;

    protected this(size_t start, size_t end) {
        _start = start;
        _end = end;
    }

    @property public Type type() {
        return _type.get();
    }

    @property public void type(Type type) {
        assert (_type.isNull());
        return _type = type;
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
public alias IntExpr = LiteralExpr!int;
public alias FloatExpr = LiteralExpr!float;

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
    private TypeName _typeName;
    private Identifier _name;

    public this(TypeName typeName, Identifier name, size_t start, size_t end) {
        _typeName = typeName;
        _name = name;
        _start = start;
        _end = end;
    }

    @property public TypeName typeName() {
        return _typeName;
    }

    @property public Identifier name() {
        return _name;
    }

    mixin sourceIndexFields;

    public override string toString() {
        return format("Declaration(%s %s)", _typeName.toString(), _name.getSource());
    }

    public static class TypeName {
        private Type _type;

        public this(KeywordType)(KeywordType keyword) {
            static if (is(KeywordType == KeywordString)) {
                _type = Type.STRING;
            } else static if (is(KeywordType == KeywordInt)) {
                _type = Type.INT;
            } else static if (is(KeywordType == KeywordFloat)) {
                _type = Type.FLOAT;
            } else {
                static assert (0);
            }
            _start = keyword.start;
            _end = keyword.end;
        }

        @property public Type type() {
            return _type;
        }

        mixin sourceIndexFields;

        public override string toString() {
            return type.to!string().toLowerCase();
        }
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
    private NameExpr _name;

    public this(NameExpr name, size_t start, size_t end) {
        super(start, end);
        _name = name;
    }

    @property public NameExpr name() {
        return _name;
    }

    public override string toString() {
        return format("Read(%s)", _name.toString());
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
    private NameExpr _name;
    private Expression _value;

    public this(NameExpr name, Expression value, size_t end) {
        super(name.start, end);
        _name = name;
        _value = value;
    }

    @property public NameExpr name() {
        return _name;
    }

    @property public Expression value() {
        return _value;
    }

    public override string toString() {
        return format("Assign(%s = %s)", _name.toString(), _value.toString());
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
