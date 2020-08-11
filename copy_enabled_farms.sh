#!/bin/sh

echo "hello from copy sh!"

for f in ./*.any; do
    # do some stuff here with "$f"
    # remember to quote it or spaces may misbehave
    cp ../available_farms/"$f" .
done