import containers;
import std.stdio;

void main() {
    DynamicArray!int arr;
    foreach (i; 0 .. 5) arr.insertBack(i * i);
    writeln("DynamicArray: ", arr[]);

    HashMap!(string, int) scores;
    scores["alice"] = 10;
    scores["bob"] = 25;
    scores["bob"] += 5;
    writeln("HashMap bob: ", scores["bob"]);

    HashSet!int set;
    foreach (i; [3, 1, 4, 1, 5]) set.insert(i);
    writeln("HashSet length: ", set.length);

    SList!string events;
    events.insertFront("spawn");
    events.insertFront("move");
    writeln("SList front: ", events.front);
}
