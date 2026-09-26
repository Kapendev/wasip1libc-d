import mir.ndslice;
import mir.math.sum;
import std.stdio;

void main() {
    auto matrix = slice!double(3, 4);
    matrix[] = 0;
    matrix.diagonal[] = 1;
    matrix[2, 3] = 6;

    writeln("shape: ", matrix.shape);
    writeln("[2,3]: ", matrix[2, 3]);
    writeln("sum: ", matrix.sum);
}
