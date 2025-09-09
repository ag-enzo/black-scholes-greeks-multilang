#!/bin/bash
# Run all Black-Scholes calculators in their respective language subfolders
# Assumes all dependencies are installed and compilers/interpreters are available in PATH

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

run_section() {
  echo "\n==================== $1 ===================="
}

# C++
run_section "C++"
cd "$ROOT_DIR/cpp"
g++ -std=c++11 -o bsm_greeks bsm_greeks.cpp && ./bsm_greeks

# Go
run_section "Go"
cd "$ROOT_DIR/go"
go run bsm_greeks.go

# Python
run_section "Python"
cd "$ROOT_DIR/python"
# Use venv if present, else system python
if [ -d ".venv" ]; then
  source .venv/bin/activate
  python bsm_greeks.py
  deactivate
else
  python3 bsm_greeks.py
fi

# TypeScript/Node.js
run_section "TypeScript/Node.js"
cd "$ROOT_DIR/ts"
if [ -f "bsm_greeks.js" ]; then
  node bsm_greeks.js
else
  npx tsc bsm_greeks.ts && node bsm_greeks.js
fi

# Lua
run_section "Lua"
cd "$ROOT_DIR/lua"
lua bsm_greeks.lua

# Java
run_section "Java"
cd "$ROOT_DIR/java"
javac BSMGreeks.java && java BSMGreeks

# Rust
run_section "Rust"
cd "$ROOT_DIR/rust"
rustc bsm_greeks.rs -o bsm_greeks && ./bsm_greeks

cd "$ROOT_DIR"
echo "\nAll calculators executed."
