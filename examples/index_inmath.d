import inmath;
import inmath.noise;
import std.stdio;

void main() {
    auto a = vec3(1, 2, 3);
    auto b = vec3(4, 5, 6);
    writeln("dot: ", dot(a, b), ", cross: ", cross(a, b));

    auto p = mat4.perspective(800, 600, 60, 0.1, 100);
    auto v = mat4.lookAt(vec3(0, 0, 5), vec3(0, 0, 0), vec3(0, 1, 0));
    writeln("mvp: ", p * v * mat4.translation(1, 2, 3));
    writeln("lerp: ", lerp(0.0f, 10.0f, 0.25f));
    osseed(1234);
    writeln("noise2: ", osnoise2(0.5, 0.25));
}
