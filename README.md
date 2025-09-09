# Multi-Language Black-Scholes Greeks & Pricing Calculator

This project provides a simple, educational implementation of the Black-Scholes-Merton (BSM) option pricing model and Greeks calculator in multiple programming languages:

- C++
- Go
- Python
- TypeScript/Node.js
- Lua
- Java
- Rust

Each implementation computes the price and Greeks (Delta, Gamma, Vega, Theta, Rho, Phi) for European options, following the same mathematical logic and conventions.

## Project Structure

- `cpp/` — C++ implementation
- `go/` — Go implementation
- `python/` — Python implementation
- `ts/` — TypeScript/Node.js implementation
- `lua/` — Lua implementation
- `java/` — Java implementation
- `rust/` — Rust implementation
- `run_all_calculators.sh` — Script to run all calculators and compare outputs

## How to Use

1. See each subfolder's `README.md` for language-specific build/run instructions.
2. To run all calculators and compare outputs, use:
   ```sh
   ./run_all_calculators.sh
   ```
   (You may need to `chmod +x run_all_calculators.sh` first.)

## Inputs & Outputs
- All implementations use the same canonical example and conventions (see `new_guide_upd.md`).
- Outputs are printed to the terminal for easy comparison.

## Why?
This project is for learning, comparison, and demonstration of how the same mathematical model can be implemented in different languages, with a focus on clarity and correctness.

## License
MIT (or specify your preferred license)
