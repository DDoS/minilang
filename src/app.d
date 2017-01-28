import std.getopt : getopt, config;
import std.stdio : writeln;
import std.file : readText, write;
import std.path : setExtension;

import minilang.source : SourceReader, SourceException;
import minilang.lexer : Lexer;
import minilang.ast : Program;
import minilang.parser : parseProgram;
import minilang.print : Printer, prettyPrint;
import minilang.symbol : SymbolTable, checkType;

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
    auto printer = new Printer();
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
