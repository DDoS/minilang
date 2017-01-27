import std.getopt : getopt, config;
import std.stdio : writeln;
import std.file : readText;

import minilang.source : SourceReader, SourceException;
import minilang.lexer : Lexer;
import minilang.parser : parseProgram;
import minilang.print : Printer, prettyPrint;

int main(string[] args) {
    // Remove the executable name from the arguments
    args = args[1 .. $];
    // Check that we have a command
    if (args.length <= 0) {
        writeln("Expected a command");
        return 1;
    }
    switch (args[0]) {
        case "parse":
            return parseCommand(args);
        case "print":
            return printCommand(args);
        default:
            writeln("Unknown command: ", args[0]);
            return 1;
    }
}

private int parseCommand(string[] args) {
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
    string source;
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
        auto program = lexer.parseProgram();
        if (printSyntax) {
            writeln(program.toString());
        }
        writeln("VALID");
        return 0;
    } catch (SourceException exception) {
        writeln("INVALID");
        writeln(exception.getErrorInformation(source).toString());
        return 1;
    }
}

private int printCommand(string[] args) {
    // Remove the "print" command from the arguments
    args = args[1 .. $];
    // Get the file text
    string source;
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
        auto program = lexer.parseProgram();
        // Print the program
        auto printer = new Printer;
        program.prettyPrint(printer);
        writeln(printer.toString());
        return 0;
    } catch (SourceException exception) {
        writeln(exception.getErrorInformation(source).toString());
        return 1;
    }
}
