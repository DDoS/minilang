module minilang.print;

import minilang.source;
import minilang.ast;
import minilang.transform;
import minilang.util;

public void prettyPrint(Program program, SourcePrinter printer) {
    foreach (declaration; program.declarations) {
        declaration.prettyPrint(printer);
        printer.newLine();
    }
    printer.newLine();
    program.statements.prettyPrint(printer);
}

public void prettyPrint(Declaration declaration, SourcePrinter printer) {
    printer.print("var ")
            .print(declaration.name.getSource())
            .print(": ")
            .print(declaration.typeName.toString())
            .print(";");
}

public void prettyPrint(ReadStmt readStmt, SourcePrinter printer) {
    printer.print("read ");
    readStmt.name.prettyPrint(printer);
    printer.print(";");
}

public void prettyPrint(PrintStmt printStmt, SourcePrinter printer) {
    printer.print("print ");
    printStmt.value.transform!prettyPrint(printer);
    printer.print(";");
}

public void prettyPrint(Assignment assignment, SourcePrinter printer) {
    assignment.name.prettyPrint(printer);
    printer.print(" = ");
    assignment.value.transform!prettyPrint(printer);
    printer.print(";");
}

public void prettyPrint(IfStmt ifStmt, SourcePrinter printer) {
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

public void prettyPrint(WhileStmt whileStmt, SourcePrinter printer) {
    printer.print("while ");
    whileStmt.condition.transform!prettyPrint(printer);
    printer.print(" do").newLine().indent();
    whileStmt.statements.prettyPrint(printer);
    printer.dedent().print("done");
}

private void prettyPrint(Statement[] statements, SourcePrinter printer) {
    foreach (statement; statements) {
        statement.transform!prettyPrint(printer);
        printer.newLine();
    }
}

public void prettyPrintSimpleExpr(SimpleExpr)(SimpleExpr simpleExpr, SourcePrinter printer) {
    printer.print(simpleExpr.toString());
}

public alias prettyPrint = prettyPrintSimpleExpr!NameExpr;
public alias prettyPrint = prettyPrintSimpleExpr!StringExpr;
public alias prettyPrint = prettyPrintSimpleExpr!IntExpr;
public alias prettyPrint = prettyPrintSimpleExpr!FloatExpr;

public void prettyPrint(NegateExpr negateExpr, SourcePrinter printer) {
    printer.print("-");
    negateExpr.inner.transform!prettyPrint(printer);
}

public void prettyPrintBinary(BinaryExpr, string operator)(BinaryExpr binaryExpr, SourcePrinter printer) {
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
