import std.getopt : getopt, config;
import std.stdio : writeln;
import std.file : readText;

import minilang.source : SourceReader, SourceException;
import minilang.lexer : Lexer;
import minilang.parser : parseProgram;

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
            return parse(args);
        default:
            writeln("Unknown command: ", args[0]);
            return 1;
    }
}

private int parse(string[] args) {
    // Get the flags for extra debug output
    bool printTokens = false, printSyntax = false;
    args.getopt(
        config.caseSensitive,
        "tokens|t", &printTokens,
        "ast|s", &printSyntax
    );
    // Remove the parse command from the arguments
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
    // Lex the file
    auto reader = new SourceReader(source);
    auto lexer = new Lexer(reader);
    try {
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
