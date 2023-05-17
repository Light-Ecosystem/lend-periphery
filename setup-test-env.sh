#!/bin/bash

# @dev
# This bash script setups the needed artifacts to use
# the lend-deploy package as source of deployment
# scripts for testing or coverage purposes.
#
# A separate  artifacts directory was created 
# due at running tests all external artifacts
# located at /artifacts are deleted,  causing
# the deploy library to not find the external
# artifacts. 

echo "[BASH] Setting up testnet environment"

if [ ! "$COVERAGE" = true ]; then
    # remove hardhat and artifacts cache
    npm run ci:clean

    # compile lend-core contracts
    npm run compile
else
    echo "[BASH] Skipping compilation to keep coverage artifacts"
fi

# Copy artifacts into separate directory to allow
# the hardhat-deploy library load all artifacts without duplicates 
mkdir -p temp-artifacts/
cp -r artifacts/* temp-artifacts/

# Create a symbolic link to reference lend-periphery package.json at node_modules
# required by lend-deploy hardhat plugin due hardhat package.json resolution
mkdir -p node_modules/lend-periphery
ln -s "$PWD/package.json" node_modules/lend-periphery/package.json

# Import external @hopeLend/deploy artifacts
mkdir -p temp-artifacts/deploy/stake
cp -r node_modules/lend-deploy/artifacts/contracts/* temp-artifacts/deploy

# Export MARKET_NAME variable to use HopeLend market as testnet deployment setup
export MARKET_NAME="Test"

echo "[BASH] Testnet environment ready"