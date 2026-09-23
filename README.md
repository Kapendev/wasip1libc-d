# Wasip1libc-d

A minimal [WASI Preview 1](https://github.com/WebAssembly/WASI) libc +
browser host for the [D programming language](https://dlang.org/).

## Quick Start

First, install [LDC](https://github.com/ldc-developers/ldc) and
the [WASI Preview 1 addon](https://github.com/ldc-developers/ldc/releases) for LDC.
The addon can be ignored if the `-betterC` flag is supported by the target project.

To install wasip1libc and build a Wasm file, run:

```sh
git clone --depth 1 https://github.com/Kapendev/wasip1libc-d
cd wasip1libc-d
./build
# Or: ./build -betterc
```

To test the Wasm file, serve the folder with:

```sh
python3 -m http.server 8080
# Or: php -S localhost:8080
```

## Notes

- Function `free` is a no-op. Allocator is a growing arena.
- Function `printf` prints only the format string.
- Things like `pthread`, `env`, and `scanf` are stubs.
- Math functions use simple implementations.
