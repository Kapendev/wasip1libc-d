import godotmath;
import std.stdio;

void main() {
    auto vel = Vector2(3, 4);
    writeln("length: ", vel.length());

    auto t2d = Transform2D(GM_PI / 4, Vector2(1, 1));
    auto p2 = t2d * Vector2(2, 3);
    writeln("rotated: ", p2.x, ", ", p2.y);

    auto screen = Rect2(0, 0, 320, 240);
    writeln("has point: ", screen.has_point(Vector2(10, 10)));

    auto a = Vector3(1, 2, 3);
    auto b = Vector3(4, 5, 6);
    writeln("dot: ", a.dot(b));

    auto rot = Basis(Vector3(0, 1, 0), GM_PI / 2);
    auto r = rot.xform(Vector3(1, 0, 0));
    writeln("rotate Y 90: ", gm_round(r.x), ", ", gm_round(r.y), ", ", gm_round(r.z));
}
