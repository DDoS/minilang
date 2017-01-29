module minilang.print;

import std.array : array;
import std.conv : to;
import std.ascii : newline;

import minilang.ast;
import minilang.transform;
import minilang.util;

public void prettyPrint(Program program, Printer printer = new Printer()) {
    foreach (declaration; program.declarations) {
        declaration.prettyPrint(printer);
        printer.newLine();
    }
    printer.newLine();
    program.statements.prettyPrint(printer);
}

public void prettyPrint(Declaration declaration, Printer printer = new Printer()) {
    printer.print("var ")
            .print(declaration.name.getSource())
            .print(": ")
            .print(declaration.typeName.toString())
            .print(";");
}

public void prettyPrint(ReadStmt readStmt, Printer printer = new Printer()) {
    printer.print("read ")
            .print(readStmt.name.getSource())
            .print(";");
}

public void prettyPrint(PrintStmt printStmt, Printer printer = new Printer()) {
    printer.print("print ");
    printStmt.value.transform!prettyPrint(printer);
    printer.print(";");
}

public void prettyPrint(Assignment assignment, Printer printer = new Printer()) {
    printer.print(assignment.name.getSource()).print(" = ");
    assignment.value.transform!prettyPrint(printer);
    printer.print(";");
}

public void prettyPrint(IfStmt ifStmt, Printer printer = new Printer()) {
    printer.print("if ");
    ifStmt.condition.transform!prettyPrint(printer);
    printer.print(" then").newLine().indent();
    ifStmt.statements.prettyPrint(printer);
    printer.dedent();
    if (ifStmt.elseBlock !is null) {
        printer.print("else").newLine().indent();
        ifStmt.elseBlock.statements.prettyPrint(printer);
        printer.dedent();
    }
    printer.print("endif");
}

public void prettyPrint(WhileStmt whileStmt, Printer printer = new Printer()) {
    printer.print("while ");
    whileStmt.condition.transform!prettyPrint(printer);
    printer.print(" do").newLine().indent();
    whileStmt.statements.prettyPrint(printer);
    printer.dedent().print("done");
}

private void prettyPrint(Statement[] statements, Printer printer = new Printer()) {
    foreach (statement; statements) {
        statement.transform!prettyPrint(printer);
        printer.newLine();
    }
}

public void prettyPrintSimpleExpr(SimpleExpr)(SimpleExpr simpleExpr, Printer printer = new Printer()) {
    printer.print(simpleExpr.toString());
}

public alias prettyPrint = prettyPrintSimpleExpr!NameExpr;
public alias prettyPrint = prettyPrintSimpleExpr!StringExpr;
public alias prettyPrint = prettyPrintSimpleExpr!IntExpr;
public alias prettyPrint = prettyPrintSimpleExpr!FloatExpr;

public void prettyPrint(NegateExpr negateExpr, Printer printer = new Printer()) {
    printer.print("-");
    negateExpr.inner.transform!prettyPrint(printer);
}

public void prettyPrintBinary(BinaryExpr, string operator)(BinaryExpr binaryExpr, Printer printer = new Printer()) {
    // Check if the left or right children have lower precenence (if so we must use parentheses)
    static if (is(BinaryExpr == MultiplyExpr) || is(BinaryExpr == DivideExpr)) {
        auto parenthesisLeft = cast(AddExpr) binaryExpr.left || cast(SubtractExpr) binaryExpr.left;
        auto parenthesisRight = cast(AddExpr) binaryExpr.right || cast(SubtractExpr) binaryExpr.right;
    } else {
        auto parenthesisLeft = false;
        auto parenthesisRight = false;
    }
    // Print the left child
    if (parenthesisLeft) {
        printer.print("(");
    }
    binaryExpr.left.transform!prettyPrint(printer);
    if (parenthesisLeft) {
        printer.print(")");
    }
    // Print the operator
    printer.print(" " ~ operator ~ " ");
    // Print the right child
    if (parenthesisRight) {
        printer.print("(");
    }
    binaryExpr.right.transform!prettyPrint(printer);
    if (parenthesisRight) {
        printer.print(")");
    }
}

public alias prettyPrint = prettyPrintBinary!(AddExpr, "+");
public alias prettyPrint = prettyPrintBinary!(SubtractExpr, "-");
public alias prettyPrint = prettyPrintBinary!(MultiplyExpr, "*");
public alias prettyPrint = prettyPrintBinary!(DivideExpr, "/");

public class Printer {
    private static enum INDENTATION = "    ";
    private char[] buffer;
    private char[] indentation;
    private bool indentNext = false;

    public this() {
        buffer.reserve(512);
        indentation.length = 0;
    }

    private Printer print(string str) {
        if (indentNext) {
            buffer ~= indentation;
            indentNext = false;
        }
        buffer ~= str;
        return this;
    }

    private Printer indent() {
        indentation ~= INDENTATION;
        return this;
    }

    private Printer dedent() {
        indentation.length -= INDENTATION.length;
        return this;
    }

    private Printer newLine() {
        buffer ~= newline;
        indentNext = true;
        return this;
    }

    public override string toString() {
        return buffer.idup;
    }
}
