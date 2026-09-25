import arsd.ini;
import std.stdio;
import std.conv;

enum rawIni = `
    title = My Game

    [window]
    width      = 1280
    height     = 720
    scale      = 1.5
    fullscreen = false

    [player]
    name  = "Alex the Brave"
    speed = 3.25
    spawn = 10, 20

    [paths]
    assets = "C:\\games\\assets"
    saves  = 'saves/slot1'
`;

void main() {
    enum dialect =
        IniDialect.defaults
        | IniDialect.hashLineComments
        | IniDialect.quotedStrings
        | IniDialect.singleQuoteQuotedStrings
        | IniDialect.escapeSequences;

    auto doc = parseIniDocument!dialect(rawIni);
    writeln("Section count: ", doc.sections.length);
    foreach (section; doc.sections) {
        writeln("[", section.name == null ? "root" : section.name, "]");
        foreach (item; section.items) writeln("  ", item.key, " = \"", item.value, "\"");
    }

    auto aa = parseIniAA!dialect(rawIni);
    auto width = aa["window"]["width"].to!int();
    auto height = aa["window"]["height"].to!int();
    auto scale = aa["window"]["scale"].to!double();
    auto fullscreen = aa["window"]["fullscreen"].to!bool();
    auto speed = aa["player"]["speed"].to!double();
    writeln("resolution = ", width, "x", height, " scaled = ", width * scale, "x", height * scale);
    writeln("fullscreen = ", fullscreen, ", speed = ", speed);
}
