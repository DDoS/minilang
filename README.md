McGill COMP 520 - Compiler Design, Fall 2017.

Assignment code.

Licensed under [MIT](LICENSE.txt).

## Description

The compiler lexer and parser were implemented by hand using work from a previous project.
It's implemented in D. The build script uses DMD by default to compile into a `bin` directory that will be created at the root of the project.

Example minilang programs are available in the `programs` directory.

The source code is composed of the following modules:

`app.d` is the command line application. The supported commands are:
- `parse [-t | --tokens] [-s | --ast] <source file>`
- `print [-t | --tokens] [-s | --ast] <source file>`
- `symbols [-t | --tokens] [-s | --ast] <source file>`
- `codegen [-t | --tokens] [-s | --ast] <source file>`
- `compile [-o <output binary>] <source file>`

The `parse` command has no output. The `print`, `symbols` and `codegen` commands output to a file in the same directory
and with the same name as the input file, but with a different extension. The `compile` command does the same unless
the output binary is specified with `-o`. This commands requires GCC, Clang or TCC to be installed and aliased to `cc`.
The `--tokens` and `--ast` flags can be used to print the data to the standard output.

`source.d` contains a `SourceReader` class for incrementally reading a string and splitting it into substrings.
It also contains a `SourcePrinter` class for printing source code, with nice support for indentation.
It also contains a template for adding source index information to other classes, and an exception class with pretty
printing of errors for data containing these source indices.

`chars.d` contains functions to discriminate between the different usages of characters, as defined in the specification.
For example: whitespace, letter, symbol, digit, etc. It also has some code to convert escape sequences to characters,
and the opposite (for error messages).

`token.d` contains all the token definitions, mostly using templates. It also has a function to check if a string is
a keyword, or a character is a symbol, and return the appropriate token instance. Tokens are split into two kinds:
fixed and regular. A fixed token only has a single string associated to it. For example the `KEYWORD_VAR` token is always
`var`. Regular tokens can have many strings, such as an int literal. They both implement the `Token` interface.

`lexer.d` contains the lexer, which is done as a lazy iterator returning one token at a time. It also supports saving
and restoring the position in a stack, which was copied from the original project and is unused in this compiler.

`ast.d` contains the AST definitions. Again this make use of templates to cut on redundancy. There are two kinds of
classes: expression and statements. The `Program` class is the root of the AST.

`parser.d` contains the parser, written using recursive descent. It builds the AST as it parses using the lexer iterator.

`transform.d` contains a dynamic dispatcher function. From a set of overloaded methods, the one with the first parameter
type that is the closest to the dynamic type of the first argument is called (or errors if none match). This allows
writing code that visits the AST to be written as a group of functions in a separate module.

`print.d` is the pretty printer. Each function visits and prints one type of node in the AST. This uses the dispatcher
from `transform.d`.

`symbol.d` is the type checker. It works much like the printer, but instead of printing it generates a symbol table.

`codegen.d` is the code generator. It works much like the printer, but it prints equivalent C code. It also contains
constant strings at the end of the module for the supporting C functions.

`util.d` contains a few functions used throughout.
