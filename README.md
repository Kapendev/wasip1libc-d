# Wasip1libc-d

A minimal [WASI Preview 1](https://github.com/WebAssembly/WASI) libc +
browser host for the [D programming language](https://dlang.org/).

## Quick Start

First, install [LDC](https://github.com/ldc-developers/ldc) and
the WASI Preview 1 addon package (can be found in the LDC releases on GitHub).

To build, run:

```sh
git clone --depth 1 https://github.com/Kapendev/wasip1libc-d
cd wasip1libc-d
./build
# Or: .\build.bat
```

Then you need to serve the folder and open `index.html`:

```
python3 -m http.server 8080
# Or: php -S localhost:8080
```

## Notes

- Function `free` is a no-op. Allocator is a growing arena.
- Function `printf` prints only the format string.
- Things like `pthread`, `env`, and `scanf` are stubs.
- Math functions use simple implementations.
