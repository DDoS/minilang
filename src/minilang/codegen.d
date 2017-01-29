module minilang.codegen;

import minilang.source;
import minilang.ast;
import minilang.transform;

private enum string[Type] minilangTypeToC = [
    Type.STRING: "char*",
    Type.INT: "int",
    Type.FLOAT: "float"
];

private enum string[Type] minilangTypeToFormat = [
    Type.STRING: "%s",
    Type.INT: "%d",
    Type.FLOAT: "%f"
];

public void codegen(Program program, SourcePrinter printer = new SourcePrinter()) {
    // Start by printing the includes
    printer.print("#include <stdio.h>").newLine();
    printer.print("#include <stdlib.h>").newLine();
    printer.print("#include <string.h>").newLine();
    printer.newLine();
    // Then add string handling code for operations on strings
    printer.print(STRING_LIST_STRUCT_TYPEDEF).newLine();
    printer.print(ADD_TO_STRING_LIST_FUNC_IMPL).newLine();
    printer.print(FREE_STRING_LIST_FUNC_IMPL).newLine();
    printer.print(APPEND_STRING_FUNC_IMPL).newLine();
    printer.print(REPEAT_STRING_FUNC_IMPL).newLine();
    // Next the main function signature
    printer.print("int main(int argc, char** argv) ");
    // Then open the body
    printer.print("{").newLine().indent();
    // Declare the string list variable to manage allocation, with a name we hope won't be used
    printer.print("StringList __stringList;").newLine()
            .print("memset(&__stringList, 0, sizeof(StringList));").newLine();
    printer.newLine();
    // Code gen the program declarations and statements
    foreach (declaration; program.declarations) {
        declaration.codegen(printer);
        printer.newLine();
    }
    printer.newLine();
    program.statements.codegen(printer);
    // Return success by default
    printer.print("return 0;").newLine();
    // Close the body
    printer.dedent().print("}").newLine();
}

public void codegen(Declaration declaration, SourcePrinter printer) {
    printer.print(minilangTypeToC[declaration.typeName.type])
            .print(" ")
            .print(declaration.name.getSource())
            .print(";");
}

public void codegen(ReadStmt readStmt, SourcePrinter printer) {
    auto nameType = readStmt.name.type;
    printer.print("scanf(\"")
            .print(minilangTypeToFormat[nameType])
            .print("\", ");
    // Must pass ints and floats as pointers
    if (nameType == Type.INT || nameType == Type.FLOAT) {
        printer.print("&");
    }
    readStmt.name.codegen(printer);
    printer.print(");");
}

public void codegen(PrintStmt printStmt, SourcePrinter printer) {
    printer.print("printf(\"")
            .print(minilangTypeToFormat[printStmt.value.type])
            .print("\", ");
    printStmt.value.transform!codegen(printer);
    printer.print(");");
}

public void codegen(Assignment assignment, SourcePrinter printer) {
    assignment.name.codegen(printer);
    printer.print(" = ");
    assignment.value.transform!codegen(printer);
    printer.print(";");
}

public void codegen(IfStmt ifStmt, SourcePrinter printer) {
    printer.print("if (");
    ifStmt.condition.transform!codegen(printer);
    printer.print(") {").newLine().indent();
    ifStmt.statements.codegen(printer);
    printer.dedent();
    if (ifStmt.elseBlock !is null) {
        printer.print("} else {").newLine().indent();
        ifStmt.elseBlock.statements.codegen(printer);
        printer.dedent();
    }
    printer.print("}");
}

public void codegen(WhileStmt whileStmt, SourcePrinter printer) {
    printer.print("while (");
    whileStmt.condition.transform!codegen(printer);
    printer.print(") {").newLine().indent();
    whileStmt.statements.codegen(printer);
    printer.dedent().print("}");
}

private void codegen(Statement[] statements, SourcePrinter printer) {
    foreach (statement; statements) {
        statement.transform!codegen(printer);
        printer.newLine();
    }
}

public void codegenSimpleExpr(SimpleExpr)(SimpleExpr simpleExpr, SourcePrinter printer) {
    printer.print(simpleExpr.toString());
}

public alias codegen = codegenSimpleExpr!NameExpr;
public alias codegen = codegenSimpleExpr!IntExpr;
public alias codegen = codegenSimpleExpr!FloatExpr;
public alias codegen = codegenSimpleExpr!StringExpr;

public void codegen(NegateExpr negateExpr, SourcePrinter printer) {
    printer.print("-");
    // Need to add a space if the inner expression is also a negation to disambiguate with the C "--" operator
    if (cast(NegateExpr) negateExpr.inner) {
        printer.print(" ");
    }
    negateExpr.inner.transform!codegen(printer);
}

public void codegenBinary(BinaryExpr, string operator)(BinaryExpr binaryExpr, SourcePrinter printer) {
    // Special cases for string operations, which are implemented as functions
    if (binaryExpr.left.type == Type.STRING) {
        static if (is(BinaryExpr == AddExpr)) {
            printer.print(APPEND_STRING_FUNC_NAME);
        } else {
            printer.print(REPEAT_STRING_FUNC_NAME);
        }
        printer.print("(&__stringList, ");
        binaryExpr.left.transform!codegen(printer);
        printer.print(", ");
        binaryExpr.right.transform!codegen(printer);
        printer.print(")");
        return;
    }
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
    binaryExpr.left.transform!codegen(printer);
    if (parenthesisLeft) {
        printer.print(")");
    }
    // Print the operator
    printer.print(" " ~ operator ~ " ");
    // Print the right child
    if (parenthesisRight) {
        printer.print("(");
    }
    binaryExpr.right.transform!codegen(printer);
    if (parenthesisRight) {
        printer.print(")");
    }
}

public alias codegen = codegenBinary!(AddExpr, "+");
public alias codegen = codegenBinary!(SubtractExpr, "-");
public alias codegen = codegenBinary!(MultiplyExpr, "*");
public alias codegen = codegenBinary!(DivideExpr, "/");

private enum STRING_LIST_STRUCT_TYPEDEF =
`typedef struct {
    size_t capacity;
    size_t length;
    char** strings;
} StringList;
`;

private enum ADD_TO_STRING_LIST_FUNC_NAME = "addStringList";
private enum ADD_TO_STRING_LIST_FUNC_IMPL =
`void ` ~ ADD_TO_STRING_LIST_FUNC_NAME ~ `(StringList* list, char* str) {
    if (list->length >= list->capacity) {
        list->capacity += 16;
        list->strings = realloc(list->strings, list->capacity * sizeof(char*));
    }
    list->strings[list->length] = str;
    list->length += 1;
}
`;

private enum FREE_STRING_LIST_FUNC_NAME = "freeStringList";
private enum FREE_STRING_LIST_FUNC_IMPL =
`void ` ~ FREE_STRING_LIST_FUNC_NAME ~ `(StringList* list) {
    for (int i = 0; i < list->length; i++) {
        free(list->strings[i]);
    }
    list->length = 0;
}
`;

private enum APPEND_STRING_FUNC_NAME = "appendStr";
private enum APPEND_STRING_FUNC_IMPL =
`char* ` ~ APPEND_STRING_FUNC_NAME ~ `(StringList* list, char* strA, char* strB) {
    size_t lengthA = strlen(strA);
    char* str = malloc((lengthA + strlen(strB) + 1) * sizeof(char));
    strcpy(str, strA);
    strcpy(str + lengthA, strB);
    addStringList(list, str);
    return str;
}
`;

private enum REPEAT_STRING_FUNC_NAME = "repeatStr";
private enum REPEAT_STRING_FUNC_IMPL =
`char* ` ~ REPEAT_STRING_FUNC_NAME ~ `(StringList* list, char* str, int times) {
    if (times < 0) {
        printf("Cannot repeat a string less than 0 times\n");
        exit(1);
    }
    size_t length = strlen(str);
    char* result = malloc((length * times + 1) * sizeof(char));
    char* p = result;
    for (int i = 0; i < times; i++) {
        strcpy(p, str);
        p += length;
    }
    *p = '\0';
    addStringList(list, result);
    return result;
}
`;
