import std.stdio : writeln;
import std.file : readText;

import minilang.source : SourceReader, SourceException;
import minilang.lexer : Lexer;

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
            return parse(args[1 .. $]);
        default:
            writeln("Unknown command: ", args[0]);
            return 1;
    }
}

private int parse(string[] args) {
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
    }
    // Lex the file
    auto reader = new SourceReader(source);
    auto lexer = new Lexer(reader);
    try {
        while (lexer.has()) {
            writeln(lexer.head().toString());
            lexer.advance();
        }
        return 0;
    } catch (SourceException exception) {
        writeln(exception.getErrorInformation(source).toString());
        return 1;
    }
}
