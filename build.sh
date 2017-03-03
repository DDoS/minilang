#/bin/bash

# The D compiler to use
DC="dmd"

# Create the bin directory if missing
mkdir -p bin

# Search for an existing DMD installation
DC_PATH="$(type -p $DC)"

# Check if DMD is installed
if [[ -z "$DC_PATH" ]]; then
    echo "No D compiler named \"$DC\" found"
    exit 1
fi

# Invoke DMD to compile to the bin directory
eval "$DC_PATH -unittest -odbin -ofbin/minilang \
    src/app.d \
    src/minilang/util.d \
    src/minilang/chars.d \
    src/minilang/source.d \
    src/minilang/token.d \
    src/minilang/lexer.d \
    src/minilang/ast.d \
    src/minilang/parser.d \
    src/minilang/transform.d \
    src/minilang/print.d \
    src/minilang/symbol.d \
    src/minilang/codegen.d \
"
