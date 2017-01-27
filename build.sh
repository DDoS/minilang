#/bin/bash

# Create the bin directory if missing
mkdir -p bin

# Search for an existing DMD installation
INSTALLED_DMD="$(type -p dmd)"

# Find the DMD build for the OS
if [[ -n "$INSTALLED_DMD" ]]; then
    # Use the installed DMD
    DMD="$INSTALLED_DMD"
elif [[ "$OSTYPE" == "linux"* ]]; then
    # Check that we are on 64bit linux
    if [[ `getconf LONG_BIT` != "64" ]]; then
        echo "Can only compile D for 64bit linux"
        exit 1
    fi
    # Use the packaged DMD
    DMD="./dmd2/linux/bin64/dmd"
else
    echo "Cannot compile D for OS: $OSTYPE"
    exit 1
fi

# This is the DMD command to build with unit tests into the bin folder
DMD_RUN="$DMD -unittest -odbin -ofbin/minilang"

# Invoke DMD to compile to the bin directory
eval "$DMD_RUN \
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
"
