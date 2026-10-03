import std.stdio;

void main() {
    writeln("Hello!!!");
}


// Below is an optional per-frame update hook.
// It's called from JS via the `requestAnimationFrame` function.
// If true is returned, then the program will stop running.
/*
import ldc.attributes;

extern(C) @llvmAttr("wasm-export-name", "_update")
bool _update(float dt) {
    static counter = 0;
    counter += 1;
    writeln("Counter: ", counter);
    return false;
}
*/
