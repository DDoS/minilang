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
    if [[ `getconf LONG_BIT` != "64" ]]; then
        echo "Cannot only compile D for 64bit linux"
        exit 1
    fi
    # Use the packaged DMD
    DMD="./dmd2/linux/bin64/dmd"
else
    echo "Cannot compile D for OS: $OSTYPE"
    exit 1
fi

# This is the DMD command to build into the bin folder
DMD_RUN="$DMD -odbin -ofbin/test"

# Invoke DMD to compile to the bin directory
eval "$DMD_RUN src/test.d"
