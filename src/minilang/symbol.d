module minilang.symbol;

import std.format : format;

import minilang.source;
import minilang.ast;
import minilang.transform;
import minilang.util;

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
    readStmt.name.checkType(symbols);
}

public void checkType(PrintStmt printStmt, SymbolTable symbols) {
    // We can print any type, so just check the expression type
    printStmt.value.transform!checkType(symbols);
}

public void checkType(Assignment assignment, SymbolTable symbols) {
    // Check the type of the variable
    assignment.name.checkType(symbols);
    auto variableType = assignment.name.type;
    // Check the assignment value type
    assignment.value.transform!checkType(symbols);
    auto valueType = assignment.value.type;
    // Only allow widening of INT to FLOAT, else it must be the same type
    if (variableType != valueType && !(variableType == Type.FLOAT && valueType == Type.INT)) {
        throw new SourceException(format("Cannot convert type %s to %s", valueType, variableType), assignment);
    }
}

public void checkType(IfStmt ifStmt, SymbolTable symbols) {
    // Only allow INT for the condition type
    ifStmt.condition.transform!checkType(symbols);
    auto conditionType = ifStmt.condition.type;
    if (conditionType != Type.INT) {
        throw new SourceException(format("Cannot use type %s for a condition", conditionType), ifStmt.condition);
    }
    // Then check the type of the statements in the blocks
    ifStmt.statements.checkType(symbols);
    if (ifStmt.elseBlock !is null) {
        ifStmt.elseBlock.statements.checkType(symbols);
    }
}

public void checkType(WhileStmt whileStmt, SymbolTable symbols) {
    // Only allow INT for the condition type
    whileStmt.condition.transform!checkType(symbols);
    auto conditionType = whileStmt.condition.type;
    if (conditionType != Type.INT) {
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

public void checkType(NameExpr nameExpr, SymbolTable symbols) {
    auto variable = nameExpr.name;
    if (!symbols.exists(variable)) {
        throw new SourceException(format("Undeclared variable \"%s\"", variable), nameExpr);
    }
    nameExpr.type = symbols.getType(variable);
}

public void checkTypeLitralExpr(LiteralExpr, Type type)(LiteralExpr literalExpr, SymbolTable symbols) {
    literalExpr.type = type;
}

public alias checkType = checkTypeLitralExpr!(StringExpr, Type.STRING);
public alias checkType = checkTypeLitralExpr!(IntExpr, Type.INT);
public alias checkType = checkTypeLitralExpr!(FloatExpr, Type.FLOAT);

public void checkType(NegateExpr negateExpr, SymbolTable symbols) {
    negateExpr.inner.transform!checkType(symbols);
    auto innerType = negateExpr.inner.type;
    if (innerType != Type.INT && innerType != Type.FLOAT) {
        throw new SourceException(format("Cannot negate type %s", innerType), negateExpr.inner);
    }
    negateExpr.type = innerType;
}

public void checkTypeBinary(BinaryExpr)(BinaryExpr binaryExpr, SymbolTable symbols) {
    // Check the types of the left and right children
    binaryExpr.left.transform!checkType(symbols);
    binaryExpr.right.transform!checkType(symbols);
    auto leftType = binaryExpr.left.type;
    auto rightType = binaryExpr.right.type;
    // If both types are the same, use that type
    if (leftType == rightType) {
        // Except only allow addition for STRING
        static if (!is(BinaryExpr == AddExpr)) {
            if (leftType == Type.STRING) {
                throw new SourceException(format("Invalid operation for types STRING"), binaryExpr);
            }
        }
        binaryExpr.type = leftType;
        return;
    }
    // If one is INT and the other FLOAT, widen to FLOAT
    if (leftType == Type.FLOAT && rightType == Type.INT) {
        binaryExpr.type = leftType;
        return;
    }
    if (leftType == Type.INT && rightType == Type.FLOAT) {
        binaryExpr.type = rightType;
        return;
    }
    // Allow multiplying a STRING by an INT
    static if (is(BinaryExpr == MultiplyExpr)) {
        if (leftType == Type.STRING && rightType == Type.INT
                || leftType == Type.INT && rightType == Type.STRING) {
            binaryExpr.type = Type.STRING;
            return;
        }
    }
    throw new SourceException(format("Invalid operation for types %s and %s", leftType, rightType), binaryExpr);
}

public alias checkType = checkTypeBinary!AddExpr;
public alias checkType = checkTypeBinary!SubtractExpr;
public alias checkType = checkTypeBinary!MultiplyExpr;
public alias checkType = checkTypeBinary!DivideExpr;
