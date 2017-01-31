module minilang.codegen;

import std.conv : to;
import std.exception : assumeUnique;
import std.range.primitives : isInputRange, ElementType;
import std.ascii : isLower, isUpper, isDigit, toLower, toUpper;
import std.algorithm.iteration : map;

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

private enum string[Type] minilangTypeToReader = [
    Type.STRING: READ_STRING_FUNC_NAME,
    Type.INT: READ_INT_FUNC_NAME,
    Type.FLOAT: READ_FLOAT_FUNC_NAME
];

private enum string[Type] minilangTypeToDefault = [
    Type.STRING: "\"\"",
    Type.INT: "0",
    Type.FLOAT: "0"
];

public void codegen(Program program, SourcePrinter printer) {
    // Start by printing the includes
    printer.print("#include <stdio.h>").newLine();
    printer.print("#include <stdlib.h>").newLine();
    printer.print("#include <string.h>").newLine();
    printer.print("#include <ctype.h>").newLine();
    printer.newLine();
    // Then add functions used to implement various operators and statements
    printer.print(REF_COUNTED_STRUCT_TYPEDEF).newLine();
    printer.print(REF_COUNT_ALLOC_STRUCT_TYPEDEF).newLine();
    printer.print(REF_COUNT_ADD_FUNC_IMPL).newLine();
    printer.print(REF_COUNT_CLEANUP_FUNC_IMPL).newLine();
    printer.print(REF_COUNT_SWAP_REF_FUNC_IMPL).newLine();
    printer.print(APPEND_STRING_FUNC_IMPL).newLine();
    printer.print(REPEAT_STRING_FUNC_IMPL).newLine();
    printer.print(READ_INT_FUNC_IMPL).newLine();
    printer.print(READ_FLOAT_FUNC_IMPL).newLine();
    printer.print(READ_STRING_FUNC_IMPL).newLine();
    // Next the main function signature
    printer.print("int main(int argc, char** argv) ");
    // Then open the body
    printer.print("{").newLine().indent();
    // Declare the string list variable to manage allocation, with a unique name
    auto allocatorName = program.declarations.map!(decl => decl.name.getSource()).uniqueToAll();
    printer.print("RefCountAlloc ").print(allocatorName).print(";").newLine()
            .print("memset(&").print(allocatorName).print(", 0, sizeof(RefCountAlloc));").newLine();
    printer.newLine();
    // Code gen the program declarations and statements
    foreach (declaration; program.declarations) {
        declaration.codegen(printer, allocatorName);
        printer.newLine();
    }
    printer.newLine();
    program.statements.codegen(printer, allocatorName);
    // Return success by default
    printer.print("return 0;").newLine();
    // Close the body
    printer.dedent().print("}").newLine();
}

public void codegen(Declaration declaration, SourcePrinter printer, string allocatorName) {
    auto type = declaration.typeName.type;
    printer.print(minilangTypeToC[type])
            .print(" ")
            .print(declaration.name.getSource())
            .print(" = ")
            .print(minilangTypeToDefault[type])
            .print(";");
}

public void codegen(ReadStmt readStmt, SourcePrinter printer, string allocatorName) {
    auto nameType = readStmt.name.type;
    if (nameType == Type.STRING) {
        printer.print(REF_COUNT_SWAP_REF_FUNC_NAME ~ "(&").print(allocatorName).print(", &");
        readStmt.name.codegen(printer, allocatorName);
        printer.print(", " ~ minilangTypeToReader[nameType] ~ "(&").print(allocatorName).print("));");
    } else {
        readStmt.name.codegen(printer, allocatorName);
        printer.print(" = ")
                .print(minilangTypeToReader[nameType])
                .print("();");
    }
}

public void codegen(PrintStmt printStmt, SourcePrinter printer, string allocatorName) {
    printer.print("printf(\"")
            .print(minilangTypeToFormat[printStmt.value.type])
            .print("\", ");
    printStmt.value.transform!codegen(printer, allocatorName);
    printer.print(");");
}

public void codegen(Assignment assignment, SourcePrinter printer, string allocatorName) {
    // Special case for strings, where we use the allocator
    if (assignment.name.type == Type.STRING) {
        printer.print(REF_COUNT_SWAP_REF_FUNC_NAME ~ "(&").print(allocatorName).print(", &");
        assignment.name.codegen(printer, allocatorName);
        printer.print(", ");
        assignment.value.transform!codegen(printer, allocatorName);
        printer.print(");");
    } else {
        assignment.name.codegen(printer, allocatorName);
        printer.print(" = ");
        assignment.value.transform!codegen(printer, allocatorName);
        printer.print(";");
    }
}

public void codegen(IfStmt ifStmt, SourcePrinter printer, string allocatorName) {
    printer.print("if (");
    ifStmt.condition.transform!codegen(printer, allocatorName);
    printer.print(") {").newLine().indent();
    ifStmt.statements.codegen(printer, allocatorName);
    printer.dedent();
    if (ifStmt.elseBlock !is null) {
        printer.print("} else {").newLine().indent();
        ifStmt.elseBlock.statements.codegen(printer, allocatorName);
        printer.dedent();
    }
    printer.print("}");
}

public void codegen(WhileStmt whileStmt, SourcePrinter printer, string allocatorName) {
    printer.print("while (");
    whileStmt.condition.transform!codegen(printer, allocatorName);
    printer.print(") {").newLine().indent();
    whileStmt.statements.codegen(printer, allocatorName);
    printer.dedent().print("}");
}

private void codegen(Statement[] statements, SourcePrinter printer, string allocatorName) {
    foreach (statement; statements) {
        statement.transform!codegen(printer, allocatorName);
        printer.newLine();
    }
}

public void codegenSimpleExpr(SimpleExpr)(SimpleExpr simpleExpr, SourcePrinter printer, string allocatorName) {
    printer.print(simpleExpr.toString());
}

public alias codegen = codegenSimpleExpr!NameExpr;
public alias codegen = codegenSimpleExpr!IntExpr;
public alias codegen = codegenSimpleExpr!FloatExpr;
public alias codegen = codegenSimpleExpr!StringExpr;

public void codegen(NegateExpr negateExpr, SourcePrinter printer, string allocatorName) {
    printer.print("-");
    // Need to add a space if the inner expression is also a negation to disambiguate with the C "--" operator
    if (cast(NegateExpr) negateExpr.inner) {
        printer.print(" ");
    }
    negateExpr.inner.transform!codegen(printer, allocatorName);
}

public void codegenBinary(BinaryExpr, string operator)(BinaryExpr binaryExpr, SourcePrinter printer, string allocatorName) {
    // Special cases for string operations, which are implemented as functions
    if (binaryExpr.left.type == Type.STRING) {
        static if (is(BinaryExpr == AddExpr)) {
            printer.print(APPEND_STRING_FUNC_NAME);
        } else {
            printer.print(REPEAT_STRING_FUNC_NAME);
        }
        printer.print("(&").print(allocatorName).print(", ");
        binaryExpr.left.transform!codegen(printer, allocatorName);
        printer.print(", ");
        binaryExpr.right.transform!codegen(printer, allocatorName);
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
    binaryExpr.left.transform!codegen(printer, allocatorName);
    if (parenthesisLeft) {
        printer.print(")");
    }
    // Print the operator
    printer.print(" " ~ operator ~ " ");
    // Print the right child
    if (parenthesisRight) {
        printer.print("(");
    }
    binaryExpr.right.transform!codegen(printer, allocatorName);
    if (parenthesisRight) {
        printer.print(")");
    }
}

public alias codegen = codegenBinary!(AddExpr, "+");
public alias codegen = codegenBinary!(SubtractExpr, "-");
public alias codegen = codegenBinary!(MultiplyExpr, "*");
public alias codegen = codegenBinary!(DivideExpr, "/");

public string uniqueToAll(Range)(Range strings) if (isInputRange!Range && is(ElementType!Range == string)) {
    char different(char c) {
        if (c.isLower()) {
            return c.toUpper();
        }
        if (c.isUpper()) {
            return c.toLower();
        }
        if (c.isDigit()) {
            return cast(char) ((c - '0' + 1) % 10 + '0');
        }
        if (c == '_') {
            return '0';
        }
        throw new Error("Not a valid identifier character: \\" ~ (cast(ubyte) c).to!string());
    }

    char[] buffer;
    size_t i = 0;
    foreach (s; strings) {
        if (i < s.length) {
            buffer ~= different(s[i]);
        } else {
            buffer ~= '_';
        }
        i += 1;
    }
    return buffer.assumeUnique();
}

private enum REF_COUNTED_STRUCT_TYPEDEF =
`typedef struct {
    size_t count;
    void* memory;
} RefCounted;
`;

private enum REF_COUNT_ALLOC_STRUCT_TYPEDEF =
`typedef struct {
    size_t capacity;
    size_t length;
    RefCounted* memories;
} RefCountAlloc;
`;

private enum REF_COUNT_ADD_FUNC_NAME = "refCountAdd";
private enum REF_COUNT_ADD_FUNC_IMPL =
`void ` ~ REF_COUNT_ADD_FUNC_NAME ~ `(RefCountAlloc* alloc, void* memory) {
    if (alloc->length >= alloc->capacity) {
        alloc->capacity += 16;
        alloc->memories = realloc(alloc->memories, alloc->capacity * sizeof(RefCounted));
    }
    RefCounted* refCounted = alloc->memories + alloc->length;
    refCounted->count = 0;
    refCounted->memory = memory;
    alloc->length += 1;
}
`;

private enum REF_COUNT_SWAP_REF_FUNC_NAME = "refCountSwapRef";
private enum REF_COUNT_SWAP_REF_FUNC_IMPL =
`void ` ~ REF_COUNT_SWAP_REF_FUNC_NAME ~ `(RefCountAlloc* alloc, void* oldPtr, void* new) {
    void* old = *(void**) oldPtr;
    for (int i = 0; i < alloc->length; i++) {
        RefCounted* refCounted = alloc->memories + i;
        // Increment the reference count of the memory being swapped in
        if (refCounted->memory == new) {
            refCounted->count += 1;
        }
        // Decrement the reference count of the memory being swapped out
        if (refCounted->memory == old) {
            refCounted->count -= 1;
        }
    }
    // Perform a cleanup of the memory
    ` ~ REF_COUNT_CLEANUP_FUNC_NAME ~ `(alloc);
    // Swap the references
    *(void**) oldPtr = new;
}
`;

private enum REF_COUNT_CLEANUP_FUNC_NAME = "refCountCleanup";
private enum REF_COUNT_CLEANUP_FUNC_IMPL =
`void ` ~ REF_COUNT_CLEANUP_FUNC_NAME ~ `(RefCountAlloc* alloc) {
    // Check if we have anything to cleanup first
    size_t length = alloc->length;
    if (length <= 0) {
        return;
    }
    RefCounted* memories = alloc->memories;
    // Start from the end
    size_t cleanEnd = length;
    do {
        // Find the last memory that has 0 references to it
        while (cleanEnd >= 1 && memories[cleanEnd - 1].count > 0) {
            cleanEnd -= 1;
        }
        // Then count all the ones that come before it that are also unreferenced
        size_t cleanStart = cleanEnd;
        while (cleanStart >= 1) {
            RefCounted* refCounted = memories + cleanStart - 1;
            if (refCounted->count <= 0) {
                // Free the memory if unused
                free(refCounted->memory);
            } else {
                // Stop at the first that is referenced
                break;
            }
            cleanStart -= 1;
        }
        // Then copy over unreferenced memories with the referenced ones that come after
        memmove(memories + cleanStart, memories + cleanEnd, (length - cleanEnd) * sizeof(RefCounted));
        // Remove the cleaned memories from the count
        length -= cleanEnd - cleanStart;
        // Loop back to clean the rest of the list
        cleanEnd = cleanStart;
    } while (cleanEnd >= 1);
    // Update the length to the one after cleanup
    alloc->length = length;
}
`;

private enum APPEND_STRING_FUNC_NAME = "appendStr";
private enum APPEND_STRING_FUNC_IMPL =
`char* ` ~ APPEND_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc, char* strA, char* strB) {
    size_t lengthA = strlen(strA);
    char* str = malloc((lengthA + strlen(strB) + 1) * sizeof(char));
    strcpy(str, strA);
    strcpy(str + lengthA, strB);
    ` ~ REF_COUNT_ADD_FUNC_NAME ~ `(alloc, str);
    return str;
}
`;

private enum REPEAT_STRING_FUNC_NAME = "repeatStr";
private enum REPEAT_STRING_FUNC_IMPL =
`char* ` ~ REPEAT_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc, char* str, int times) {
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
    ` ~ REF_COUNT_ADD_FUNC_NAME ~ `(alloc, result);
    return result;
}
`;

private enum READ_INT_FUNC_NAME = "readInt";
private enum READ_INT_FUNC_IMPL =
`int ` ~ READ_INT_FUNC_NAME ~ `() {
    int i;
    while (scanf("%d", &i) != 1) {
        while (getchar() != '\n') {
        }
    }
    return i;
}
`;

private enum READ_FLOAT_FUNC_NAME = "readFloat";
private enum READ_FLOAT_FUNC_IMPL =
`float ` ~ READ_FLOAT_FUNC_NAME ~ `() {
    float f;
    while (scanf("%f", &f) != 1) {
        while (getchar() != '\n') {
        }
    }
    return f;
}
`;

private enum READ_STRING_FUNC_NAME = "readString";
private enum READ_STRING_FUNC_IMPL =
`char* ` ~ READ_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc) {
    size_t capacity = 0;
    size_t length = 1;
    char* str = NULL;
    char c;
    while ((c = getchar()) != EOF && !isspace(c)) {
        if (length >= capacity) {
            capacity += 16;
            str = realloc(str, capacity * sizeof(char));
        }
        str[length - 1] = c;
        length += 1;
    }
    if (str == NULL) {
        str = "";
    } else {
        str[length - 1] = '\0';
        ` ~ REF_COUNT_ADD_FUNC_NAME ~ `(alloc, str);
    }
    return str;
}
`;
