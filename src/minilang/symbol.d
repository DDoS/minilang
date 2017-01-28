module minilang.symbol;

import std.format : format;

import minilang.source;
import minilang.ast;
import minilang.transform;
import minilang.util;

private alias Type = Declaration.TypeName.Type;

public class SymbolTable {
    private Type[string] variableToType;

    private bool exists(string variable) {
        return (variable in variableToType) !is null;
    }

    private Type getType(string variable) {
        return variableToType[variable];
    }

    private void declare(string variable, Type type) {
        assert (!exists(variable));
        variableToType[variable] = type;
    }

    public override string toString() {
        string[] rowStrings;
        foreach (variable, type; variableToType) {
            rowStrings ~= format("var %s: %s", variable, type);
        }
        return rowStrings.join!"\n"();
    }
}

public void checkType(Program program, SymbolTable symbols = new SymbolTable()) {
    foreach (declaration; program.declarations) {
        declaration.checkType(symbols);
    }
    program.statements.checkType(symbols);
}

public void checkType(Declaration declaration, SymbolTable symbols) {
    auto variable = declaration.name.getSource();
    if (symbols.exists(variable)) {
        throw new SourceException(format("Variable \"%s\" is already declared", variable), declaration.name);
    }
    symbols.declare(variable, declaration.typeName.type);
}

public void checkType(ReadStmt readStmt, SymbolTable symbols) {
    auto variable = readStmt.name.getSource();
    if (!symbols.exists(variable)) {
        throw new SourceException(format("Undeclared variable \"%s\"", variable), readStmt.name);
    }
}

public void checkType(PrintStmt printStmt, SymbolTable symbols) {
    // We can print any type, so just check the expression type
    printStmt.value.transform!getType(symbols);
}

public void checkType(Assignment assignment, SymbolTable symbols) {
    auto variable = assignment.name.getSource();
    if (!symbols.exists(variable)) {
        throw new SourceException(format("Undeclared variable \"%s\"", variable), assignment.name);
    }
    auto variableType = symbols.getType(variable);
    auto valueType = assignment.value.transform!getType(symbols);
    // Only allow widening of INT to FLOAT, else it must be the same type
    if (variableType != valueType && !(variableType == Type.FLOAT && valueType == Type.INT)) {
        throw new SourceException(format("Cannot convert type %s to %s", valueType, variableType), assignment);
    }
}

public void checkType(IfStmt ifStmt, SymbolTable symbols) {
    // Only allow INT or FLOAT for the condition type
    auto conditionType = ifStmt.condition.transform!getType(symbols);
    if (conditionType != Type.INT && conditionType != Type.FLOAT) {
        throw new SourceException(format("Cannot use type %s for a condition", conditionType), ifStmt.condition);
    }
    // Then check the type of the statements in the blocks
    ifStmt.statements.checkType(symbols);
    if (ifStmt.elseBlock !is null) {
        ifStmt.elseBlock.statements.checkType(symbols);
    }
}

public void checkType(WhileStmt whileStmt, SymbolTable symbols) {
    // Only allow INT or FLOAT for the condition type
    auto conditionType = whileStmt.condition.transform!getType(symbols);
    if (conditionType != Type.INT && conditionType != Type.FLOAT) {
        throw new SourceException(format("Cannot use type %s for a condition", conditionType), whileStmt.condition);
    }
    // Then check the type of the statements in the block
    whileStmt.statements.checkType(symbols);
}

public void checkType(Statement[] statements, SymbolTable symbols) {
    foreach (statement; statements) {
        statement.transform!checkType(symbols);
    }
}

public Type getType(NameExpr nameExpr, SymbolTable symbols) {
    auto variable = nameExpr.name;
    if (!symbols.exists(variable)) {
        throw new SourceException(format("Undeclared variable \"%s\"", variable), nameExpr);
    }
    return symbols.getType(variable);
}

public Type getTypeLitralExpr(LiteralExpr, Type type)(LiteralExpr literalExpr, SymbolTable symbols) {
    return type;
}

public alias getType = getTypeLitralExpr!(StringExpr, Type.STRING);
public alias getType = getTypeLitralExpr!(IntExpr, Type.INT);
public alias getType = getTypeLitralExpr!(FloatExpr, Type.FLOAT);

public Type getType(NegateExpr negateExpr, SymbolTable symbols) {
    auto innerType = negateExpr.inner.transform!getType(symbols);
    if (innerType == Type.INT || innerType == Type.FLOAT) {
        return innerType;
    }
    throw new SourceException(format("Cannot negate type %s", innerType), negateExpr.inner);
}

public Type getTypeBinary(BinaryExpr)(BinaryExpr binaryExpr, SymbolTable symbols) {
    auto leftType = binaryExpr.left.transform!getType(symbols);
    auto rightType = binaryExpr.right.transform!getType(symbols);
    if (leftType == rightType) {
        // Only allow adding two strings
        static if (!is(BinaryExpr == AddExpr)) {
            if (leftType == Type.STRING) {
                throw new SourceException(format("Invalid operator for type STRING"), binaryExpr);
            }
        }
        return leftType;
    }
    // If one is INT and the other FLOAT, widen to FLOAT
    if (leftType == Type.FLOAT && rightType == Type.INT) {
        return leftType;
    }
    if (leftType == Type.INT && rightType == Type.FLOAT) {
        return rightType;
    }
    throw new SourceException(format("Invalid operator for types %s and %s", leftType, rightType), binaryExpr);
}

public alias getType = getTypeBinary!AddExpr;
public alias getType = getTypeBinary!SubtractExpr;
public alias getType = getTypeBinary!MultiplyExpr;
public alias getType = getTypeBinary!DivideExpr;
