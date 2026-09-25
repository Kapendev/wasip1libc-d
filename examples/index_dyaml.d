import dyaml;
import std.stdio;

enum config = `
player:
  name: Alex
  hp: 100
  items: [sword, potion]
enemies:
  - name: slime
    hp: 12
  - name: goblin
    hp: 30
`;

void main() {
    auto root = Loader.fromString(config).load();
    auto player = root["player"];
    writeln(player["name"].as!string(), " hp: ", player["hp"].as!int());

    foreach (string item; player["items"]) writeln("- ", item);
    foreach (Node enemy; root["enemies"]) writeln(enemy["name"].as!string(), " hp: ", enemy["hp"].as!int());
    player["hp"] = 80;
    writeln("after damage hp: ", player["hp"].as!int());
}
