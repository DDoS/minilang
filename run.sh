#/bin/bash

./bin/minilang print "$1"
if [[ "$?" != 0 ]]; then
    exit 1
fi

./bin/minilang symbols "$1"
if [[ "$?" != 0 ]]; then
    exit 1
fi

./bin/minilang codegen "$1"
