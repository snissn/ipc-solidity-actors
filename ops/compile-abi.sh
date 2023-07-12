#!/bin/bash
# Compile contract and output core contracts ABI
set -e

if [ $# -ne 1 ]
then
    echo "Expected a single argument with the output directory for the compiled contracts"
    exit 1
fi

OUTPUT=$1

echo "[*] Compiling contracts and output core contracts ABI in $OUTPUT" 
forge build --via-ir --extra-output=abi --out=$OUTPUT
mkdir -p $OUTPUT
cp $OUTPUT/SubnetActor.sol/* $OUTPUT
cp $OUTPUT/Gateway.sol/* $OUTPUT
cp $OUTPUT/SubnetRegistry.sol/* $OUTPUT