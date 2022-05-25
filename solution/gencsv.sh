#!/bin/bash

N="${1:-10}"

for (( i=0; i<$N; i++ )); do echo "$i, $(( $RANDOM % 100000 + 1 ))"; done > inputFile

