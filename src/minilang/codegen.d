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
    Type.FLOAT: "0.0"
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
    printer.print(REF_COUNT_HOLD_FUNC_IMPL).newLine();
    printer.print(REF_COUNT_RELEASE_FUNC_IMPL).newLine();
    printer.print(REF_COUNT_SWAP_FUNC_IMPL).newLine();
    printer.print(APPEND_STRING_FUNC_IMPL).newLine();
    printer.print(REPEAT_LEFT_STRING_FUNC_IMPL).newLine();
    printer.print(REPEAT_RIGHT_STRING_FUNC_IMPL).newLine();
    printer.print(READ_INT_FUNC_IMPL).newLine();
    printer.print(READ_FLOAT_FUNC_IMPL).newLine();
    printer.print(READ_STRING_FUNC_IMPL).newLine();
    printer.print(PRINT_STRING_FUNC_IMPL).newLine();
    // Next the main function signature
    printer.print("int main(int argc, char** argv) ");
    // Then open the body
    printer.print("{").newLine().indent();
    // Declare the allocator variable with a unique name
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
        printer.print(REF_COUNT_SWAP_FUNC_NAME ~ "(&").print(allocatorName).print(", &");
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
    // Special case for strings, to ensure that memory is managed
    if (printStmt.value.type == Type.STRING) {
        printer.print(PRINT_STRING_FUNC_NAME ~ "(&").print(allocatorName).print(", ");
        printStmt.value.transform!codegen(printer, allocatorName);
        printer.print(");");
    } else {
        printer.print("printf(\"")
                .print(minilangTypeToFormat[printStmt.value.type])
                .print("\", ");
        printStmt.value.transform!codegen(printer, allocatorName);
        printer.print(");");
    }
}

public void codegen(Assignment assignment, SourcePrinter printer, string allocatorName) {
    // Special case for strings, where we use the allocator
    if (assignment.name.type == Type.STRING) {
        printer.print(REF_COUNT_SWAP_FUNC_NAME ~ "(&").print(allocatorName).print(", &");
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
    if (binaryExpr.type == Type.STRING) {
        static if (is(BinaryExpr == AddExpr)) {
            printer.print(APPEND_STRING_FUNC_NAME);
        } else {
            if (binaryExpr.left.type == Type.STRING) {
                printer.print(REPEAT_LEFT_STRING_FUNC_NAME);
            } else {
                printer.print(REPEAT_RIGHT_STRING_FUNC_NAME);
            }
        }
        printer.print("(&").print(allocatorName).print(", ");
        binaryExpr.left.transform!codegen(printer, allocatorName);
        printer.print(", ");
        binaryExpr.right.transform!codegen(printer, allocatorName);
        printer.print(")");
        return;
    }
    // Check if the left or right children have lower precedence (if so we must use parentheses)
    static if (is(BinaryExpr == MultiplyExpr) || is(BinaryExpr == DivideExpr)) {
        auto parenthesisLeft = cast(AddExpr) binaryExpr.left || cast(SubtractExpr) binaryExpr.left;
        auto parenthesisRight = cast(AddExpr) binaryExpr.right || cast(SubtractExpr) binaryExpr.right;
    } else {
        auto parenthesisLeft = false;
        // Add parentheses to the right child if the precedence is the same to respect associativity
        auto parenthesisRight = cast(AddExpr) binaryExpr.right || cast(SubtractExpr) binaryExpr.right;
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

    if (strings.empty) {
        return "a";
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
    // Check that it wasn't added first (don't re-add)
    for (size_t i = 0; i < alloc->length; i++) {
        if ((alloc->memories + i)->memory == memory) {
            return;
        }
    }
    // Make room in the list if needed
    if (alloc->length >= alloc->capacity) {
        alloc->capacity += 16;
        alloc->memories = realloc(alloc->memories, alloc->capacity * sizeof(RefCounted));
    }
    // Add to the list
    RefCounted* refCounted = alloc->memories + alloc->length;
    refCounted->count = 0;
    refCounted->memory = memory;
    alloc->length += 1;
}
`;

private enum REF_COUNT_HOLD_FUNC_NAME = "refCountHold";
private enum REF_COUNT_HOLD_FUNC_IMPL =
`void ` ~ REF_COUNT_HOLD_FUNC_NAME ~ `(RefCountAlloc* alloc, void* memory) {
    // Increment the reference count
    for (size_t i = 0; i < alloc->length; i++) {
        RefCounted* refCounted = alloc->memories + i;
        if (refCounted->memory == memory) {
            refCounted->count += 1;
            break;
        }
    }
}`;

private enum REF_COUNT_RELEASE_FUNC_NAME = "refCountRelease";
private enum REF_COUNT_RELEASE_FUNC_IMPL =
`void ` ~ REF_COUNT_RELEASE_FUNC_NAME ~ `(RefCountAlloc* alloc, void* memory) {
    RefCounted* memories = alloc->memories;
    size_t length = alloc->length;
    RefCounted* refCounted;
    size_t index;
    // Decrement the reference count
    for (index = 0; index < length; index++) {
        refCounted = memories + index;
        if (refCounted->memory == memory) {
            if (refCounted->count > 0) {
                refCounted->count -= 1;
            }
            break;
        }
    }
    // If the reference count hits 0, then free and remove
    if (index >= length || refCounted->count > 0) {
        return;
    }
    free(memory);
    size_t nextIndex = index + 1;
    memmove(memories + index, memories + nextIndex, (length - nextIndex) * sizeof(RefCounted));
     alloc->length = length - 1;
}
`;

private enum REF_COUNT_SWAP_FUNC_NAME = "refCountSwap";
private enum REF_COUNT_SWAP_FUNC_IMPL =
`void ` ~ REF_COUNT_SWAP_FUNC_NAME ~ `(RefCountAlloc* alloc, void* oldPtr, void* new) {
    void* old = *(void**) oldPtr;
    // Increment the reference count of the new memory
    refCountHold(alloc, new);
    // Decrement the reference count of the old memory
    refCountRelease(alloc, old);
    // Swap the references
    *(void**) oldPtr = new;
}
`;

private enum APPEND_STRING_FUNC_NAME = "appendStr";
private enum APPEND_STRING_FUNC_IMPL =
`char* ` ~ APPEND_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc, char* strA, char* strB) {
    refCountHold(alloc, strA);
    refCountHold(alloc, strB);
    size_t lengthA = strlen(strA);
    char* str = malloc((lengthA + strlen(strB) + 1) * sizeof(char));
    strcpy(str, strA);
    strcpy(str + lengthA, strB);
    refCountRelease(alloc, strA);
    refCountRelease(alloc, strB);
    refCountAdd(alloc, str);
    return str;
}
`;

private enum REPEAT_LEFT_STRING_FUNC_NAME = "repeatLeftStr";
private enum REPEAT_LEFT_STRING_FUNC_IMPL =
`char* ` ~ REPEAT_LEFT_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc, char* str, int times) {
    if (times < 0) {
        printf("Cannot repeat a string less than 0 times\n");
        exit(1);
    }
    refCountHold(alloc, str);
    size_t length = strlen(str);
    char* result = malloc((length * times + 1) * sizeof(char));
    char* p = result;
    for (int i = 0; i < times; i++) {
        strcpy(p, str);
        p += length;
    }
    *p = '\0';
    refCountRelease(alloc, str);
    refCountAdd(alloc, result);
    return result;
}
`;

private enum REPEAT_RIGHT_STRING_FUNC_NAME = "repeatRightStr";
private enum REPEAT_RIGHT_STRING_FUNC_IMPL =
`char* ` ~ REPEAT_RIGHT_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc, int times, char* str) {
    return repeatLeftStr(alloc, str, times);
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
        refCountAdd(alloc, str);
    }
    return str;
}
`;

private enum PRINT_STRING_FUNC_NAME = "printString";
private enum PRINT_STRING_FUNC_IMPL =
`void ` ~ PRINT_STRING_FUNC_NAME ~ `(RefCountAlloc* alloc, char* str) {
    refCountHold(alloc, str);
    printf("%s", str);
    refCountRelease(alloc, str);
}
`;
