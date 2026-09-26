# Library Examples

This folder includes examples that use:

- **[inmath](https://github.com/Inochi2D/inmath)**: Games math library for D
- **[text-mode](https://github.com/AuburnSounds/text-mode)**: Virtual text mode with 8x8 Unicode font and markup language
- **[EMSI containers](https://github.com/dlang-community/containers)**: Containers backed by std.experimental.allocator
- **[D-YAML](https://github.com/dlang-community/D-YAML)**: YAML parser and emitter for the D programming language
- **[dlib](https://github.com/gecko0307/dlib)**: Allocators, I/O streams, math, geometry, image and audio processing for D
- **[godot-math](https://github.com/AuburnSounds/godot-math)**: Port of godot-math to D: vectors, matrices, rectangles, points, AABBs, planes, frustums
- **[arsd](https://github.com/adamdruppe/arsd)**: A collection of modules
- **[mir](https://github.com/libmir)**: Numerical libraries

## Setup

Run this inside the wasip1libc-d folder:

```sh
mkdir -p examples/packages

[ -d examples/packages/inmath_package ] || git clone --depth 1 https://github.com/Inochi2D/inmath examples/packages/inmath_package
[ -d examples/packages/text-mode_package ] || git clone --depth 1 https://github.com/AuburnSounds/text-mode examples/packages/text-mode_package
[ -d examples/packages/intel-intrinsics_package ] || git clone --depth 1 https://github.com/AuburnSounds/intel-intrinsics examples/packages/intel-intrinsics_package
[ -d examples/packages/miniz_package ] || git clone --depth 1 https://github.com/AuburnSounds/miniz examples/packages/miniz_package
[ -d examples/packages/containers_package ] || git clone --depth 1 https://github.com/dlang-community/containers examples/packages/containers_package
[ -d examples/packages/D-YAML_package ] || git clone --depth 1 https://github.com/dlang-community/D-YAML examples/packages/D-YAML_package
[ -d examples/packages/dlib_package ] || git clone --depth 1 https://github.com/gecko0307/dlib examples/packages/dlib_package
[ -d examples/packages/godot-math_package ] || git clone --depth 1 https://github.com/AuburnSounds/godot-math examples/packages/godot-math_package
[ -d examples/packages/numem_package ] || git clone --depth 1 https://github.com/Inochi2D/numem examples/packages/numem_package
[ -d examples/packages/arsd_package ] || git clone --depth 1 https://github.com/adamdruppe/arsd examples/packages/arsd_package
[ -d examples/packages/mir-algorithm_package ] || git clone --depth 1 https://github.com/libmir/mir-algorithm examples/packages/mir-algorithm_package
[ -d examples/packages/mir-core_package ] || git clone --depth 1 https://github.com/libmir/mir-core examples/packages/mir-core_package

rm -rf mir
mkdir -p mir
cp -R examples/packages/mir-core_package/source/mir/. mir/
cp -R examples/packages/mir-algorithm_package/source/mir/. mir/

ln -snf examples/packages/inmath_package/inmath inmath
ln -snf examples/packages/text-mode_package/source/textmode.d textmode.d
ln -snf examples/packages/text-mode_package/source/rectlist.d rectlist.d
ln -snf examples/packages/miniz_package/source/miniz.d miniz.d
ln -snf examples/packages/intel-intrinsics_package/source/inteli inteli
ln -snf examples/packages/containers_package/src/containers containers
ln -snf examples/packages/D-YAML_package/source/dyaml dyaml
ln -snf examples/packages/dlib_package/dlib dlib
ln -snf examples/packages/godot-math_package/source/godotmath.d godotmath.d
ln -snf examples/packages/numem_package/source/numem numem
ln -snf examples/packages/arsd_package arsd
```

## Running Examples

Copy the example over to `index.d`, then build:

```sh
cat examples/index_arsd_color.d > index.d
./build
```

To remove the links:

```sh
rm -f inmath arsd textmode.d rectlist.d miniz.d inteli containers dyaml dlib godotmath.d numem
rm -rf mir
```
