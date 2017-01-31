#/bin/bash

./bin/minilang print "$1"
if [[ "$?" != 0 ]]; then
    exit "$?"
fi

./bin/minilang symbols "$1"
if [[ "$?" != 0 ]]; then
    exit "$?"
fi

./bin/minilang codegen "$1"
