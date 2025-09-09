#!/bin/bash
# Benchmark all Black-Scholes calculators: execution time and binary size (where applicable)
# Results are printed in a summary table at the end

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Table headers
printf "\n%-18s %-12s %-12s %-12s\n" "Language" "Time (s)" "Binary Size" "Notes"
printf "%-18s %-12s %-12s %-12s\n" "------------------" "------------" "------------" "------------"

# Helper to time and report
benchmark() {
  lang="$1"
  build_cmd="$2"
  run_cmd="$3"
  bin_path="$4"
  notes="$5"
  cd "$ROOT_DIR/$lang"
  # Build if needed
  if [ -n "$build_cmd" ]; then eval "$build_cmd"; fi
  # Get binary size if applicable
  if [ -n "$bin_path" ] && [ -f "$bin_path" ]; then
    bin_size=$(ls -lh "$bin_path" | awk '{print $5}')
  else
    bin_size="-"
  fi
  # Time the execution (wrap in bash -c for complex commands)
  exec_time=$( (/usr/bin/time -f "%e" bash -c "$run_cmd" > /dev/null) 2>&1 )
  # Print result
  printf "%-18s %-12s %-12s %-12s\n" "$lang" "$exec_time" "$bin_size" "$notes"
  cd "$ROOT_DIR"
}

# C++
benchmark "cpp" "g++ -std=c++11 -o bsm_greeks bsm_greeks.cpp" "./bsm_greeks" "bsm_greeks" "Compiled"
# Go
benchmark "go" "" "go run bsm_greeks.go" "" "Interpreted/Go run"
# Python
if [ -d "$ROOT_DIR/python/.venv" ]; then
  benchmark "python" "" 'source .venv/bin/activate && python bsm_greeks.py && deactivate' "" "Python venv"
else
  benchmark "python" "" 'python3 bsm_greeks.py' "" "System Python"
fi
# TypeScript/Node.js
if [ -f "$ROOT_DIR/ts/bsm_greeks.js" ]; then
  benchmark "ts" "" "node bsm_greeks.js" "" "Node.js"
else
  benchmark "ts" "npx tsc bsm_greeks.ts" "node bsm_greeks.js" "" "Node.js (tsc)"
fi
# Lua
benchmark "lua" "" "lua bsm_greeks.lua" "" "Lua"
# Java
benchmark "java" "javac BSMGreeks.java" "java BSMGreeks" "BSMGreeks.class" "JVM"
# Rust
benchmark "rust" "rustc bsm_greeks.rs -o bsm_greeks" "./bsm_greeks" "bsm_greeks" "Compiled"

echo "\nBenchmarking complete."
