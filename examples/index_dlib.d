import dlib.container.array;
import dlib.container.dict;
import dlib.core.memory;
import dlib.serialization.json;
import std.stdio;

enum saveJson = `{
    "player": "Alex",
    "level": 7,
    "hp": 82.5,
    "inventory": ["sword", "potion"]
}`;

void main() {
    Array!int arr;
    foreach (i; 0 .. 5) arr.append(i * i);
    writeln("Array: ", arr.data);
    arr.free();

    auto scores = dict!(int, string)();
    scores["alice"] = 10;
    scores["bob"] = 25;
    writeln("alice: ", scores["alice"], ", bob: ", scores["bob"]);
    Delete(scores);

    auto doc = New!JSONDocument(saveJson);
    auto root = doc.root.asObject;
    writeln(root["player"].asString, " level ", root["level"].asNumber);
    Delete(doc);
}
