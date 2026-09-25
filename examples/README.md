# D Libraries

This folder includes examples that use:

- **[inmath](https://github.com/Inochi2D/inmath)**: games math
- **[arsd.ini](https://github.com/adamdruppe/arsd)**: module collection
- **[text-mode](https://github.com/AuburnSounds/text-mode)**: virtual console
- **[EMSI containers](https://github.com/dlang-community/containers)**: allocator containers
- **[D-YAML](https://github.com/dlang-community/D-YAML)**: YAML parser
- **[dlib](https://github.com/gecko0307/dlib)**: utility library
- **[godot-math](https://github.com/AuburnSounds/godot-math)**: Godot math

## Setup

Run this inside the wasip1libc-d folder:

```sh
mkdir -p examples/packages

[ -d examples/packages/inmath_package ] || git clone --depth 1 https://github.com/Inochi2D/inmath examples/packages/inmath_package
[ -d examples/packages/arsd_package ] || git clone --depth 1 https://github.com/adamdruppe/arsd examples/packages/arsd_package
[ -d examples/packages/text-mode_package ] || git clone --depth 1 https://github.com/AuburnSounds/text-mode examples/packages/text-mode_package
[ -d examples/packages/intel-intrinsics_package ] || git clone --depth 1 https://github.com/AuburnSounds/intel-intrinsics examples/packages/intel-intrinsics_package
[ -d examples/packages/miniz_package ] || git clone --depth 1 https://github.com/AuburnSounds/miniz examples/packages/miniz_package
[ -d examples/packages/containers_package ] || git clone --depth 1 https://github.com/dlang-community/containers examples/packages/containers_package
[ -d examples/packages/D-YAML_package ] || git clone --depth 1 https://github.com/dlang-community/D-YAML examples/packages/D-YAML_package
[ -d examples/packages/dlib_package ] || git clone --depth 1 https://github.com/gecko0307/dlib examples/packages/dlib_package
[ -d examples/packages/godot-math_package ] || git clone --depth 1 https://github.com/AuburnSounds/godot-math examples/packages/godot-math_package
[ -d examples/packages/numem_package ] || git clone --depth 1 https://github.com/Inochi2D/numem examples/packages/numem_package

ln -snf examples/packages/inmath_package/inmath inmath
ln -snf examples/packages/arsd_package arsd
ln -snf examples/packages/text-mode_package/source/textmode.d textmode.d
ln -snf examples/packages/text-mode_package/source/rectlist.d rectlist.d
ln -snf examples/packages/miniz_package/source/miniz.d miniz.d
ln -snf examples/packages/intel-intrinsics_package/source/inteli inteli
ln -snf examples/packages/containers_package/src/containers containers
ln -snf examples/packages/D-YAML_package/source/dyaml dyaml
ln -snf examples/packages/dlib_package/dlib dlib
ln -snf examples/packages/godot-math_package/source/godotmath.d godotmath.d
ln -snf examples/packages/numem_package/source/numem numem
```

## Running Examples

Copy the example over `index.d`, then run the build script.
To remove the links, run:

```sh
rm -f inmath arsd textmode.d rectlist.d miniz.d inteli containers dyaml dlib godotmath.d numem
```
