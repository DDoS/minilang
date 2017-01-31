import std.getopt : getopt, config;
import std.stdio : writeln;
import std.file : readText, write;
import std.path : setExtension;
import std.process : Redirect, pipeProcess, wait;

import minilang.source : SourceReader, SourcePrinter, SourceException;
import minilang.lexer : Lexer;
import minilang.ast : Program;
import minilang.parser : parseProgram;
import minilang.print : prettyPrint;
import minilang.symbol : SymbolTable, checkType;
import minilang.codegen : codegen;

int main(string[] args) {
    // Remove the executable name from the arguments
    args = args[1 .. $];
    // Check that we have a command
    if (args.length <= 0) {
        writeln("Expected a command");
        return 1;
    }
    // Execute the command
    switch (args[0]) {
        case "parse":
            return parseCommand(args);
        case "print":
            return printCommand(args);
        case "symbols":
            return symbolsCommand(args);
        case "codegen":
            return codegenCommand(args);
        case "compile":
            return compileCommand(args);
        default:
            writeln("Unknown command: ", args[0]);
            return 1;
    }
}

private int parseCommand(ref string[] args) {
    string source = void;
    Program program = void;
    return parseCommand(args, source, program);
}

private int parseCommand(ref string[] args, out string source, out Program program) {
    source = null;
    program = null;
    // Get the flags for extra debug output
    bool printTokens = false, printSyntax = false;
    args.getopt(
        config.caseSensitive,
        "tokens|t", &printTokens,
        "ast|s", &printSyntax
    );
    // Remove the "parse" command from the arguments
    args = args[1 .. $];
    // Check that we have the file to parse as an argument
    if (args.length <= 0) {
        writeln("Expected a file path");
        return 1;
    }
    // Get the file text
    try {
        source = args[0].readText();
    } catch (Exception exception) {
        writeln("Could not read file: ", exception.msg);
        return 1;
    }
    // Lex and parse the file
    try {
        auto reader = new SourceReader(source);
        auto lexer = new Lexer(reader);
        if (printTokens) {
            lexer.savePosition();
            while (lexer.has()) {
                writeln(lexer.head().toString());
                lexer.advance();
            }
            lexer.restorePosition();
        }
        program = lexer.parseProgram();
        if (printSyntax) {
            writeln(program.toString());
        }
        return 0;
    } catch (SourceException exception) {
        writeln(exception.getErrorInformation(source).toString());
        return 1;
    }
}

private int printCommand(string[] args) {
    // First call the parse command
    string source = void;
    Program program = void;
    if (parseCommand(args, source, program)) {
        return 1;
    }
    // Next get the path of the output file
    auto prettyOutput = args[0].setExtension(".pretty.min");
    // Then do the pretty printing
    auto printer = new SourcePrinter();
    program.prettyPrint(printer);
    // Write the printed output to the file
    prettyOutput.write(printer.toString());
    return 0;
}

private int symbolsCommand(string[] args) {
    // First call the parse command
    string source = void;
    Program program = void;
    if (parseCommand(args, source, program)) {
        return 1;
    }
    // Next get the path of the output file
    auto symbolOutput = args[0].setExtension(".symbol.min");
    // Then do the type checking
    auto symbols = new SymbolTable();
    int succcess = void;
    try {
        program.checkType(symbols);
        succcess = 0;
    } catch (SourceException exception) {
        writeln(exception.getErrorInformation(source).toString());
        succcess = 1;
    }
    // Write the symbol output to the file
    symbolOutput.write(symbols.toString());
    return succcess;
}

private int codegenCommand(string[] args) {
    // First call the parse command
    string source = void;
    Program program = void;
    if (parseCommand(args, source, program)) {
        return 1;
    }
    // Next get the path of the output file
    auto codeOutput = args[0].setExtension(".c");
    // Then do the type checking
    try {
        program.checkType();
    } catch (SourceException exception) {
        writeln(exception.getErrorInformation(source).toString());
        return 1;
    }
    // Then do the code gen
    auto printer = new SourcePrinter();
    program.codegen(printer);
    // Write the printed output to the file
    codeOutput.write(printer.toString());
    return 0;
}

private int compileCommand(string[] args) {
    // First get the path of the output file (might not exists)
    string outputBin = null;
    args.getopt(config.caseSensitive, "output|o", &outputBin);
    // Remove the "compile" command from the arguments
    args = args[1 .. $];
    // Check that we have the source to parse as an argument
    if (args.length <= 0) {
        writeln("Expected a file path");
        return 1;
    }
    auto inputSource = args[0];
    // If no output source was specified, use the input one without an extension
    if (outputBin is null) {
        outputBin = inputSource.setExtension("");
    }
    // Get the source text
    string source = void;
    try {
        source = inputSource.readText();
    } catch (Exception exception) {
        writeln("Could not read file: ", exception.msg);
        return 1;
    }
    // Then do the lexing, parsing and type checking
    Program program = void;
    try {
        auto reader = new SourceReader(source);
        auto lexer = new Lexer(reader);
        program = lexer.parseProgram();
        program.checkType();
    } catch (SourceException exception) {
        writeln(exception.getErrorInformation(source).toString());
        return 1;
    }
    // Then do the code gen
    auto printer = new SourcePrinter();
    program.codegen(printer);
    // Finally pass the source code to the default C compiler
    auto pipe = pipeProcess(["cc", "-xc", "-o", outputBin, "-"], Redirect.stdin);
    pipe.stdin.write(printer.toString());
    pipe.stdin.flush();
    pipe.stdin.close();
    return wait(pipe.pid);
}
