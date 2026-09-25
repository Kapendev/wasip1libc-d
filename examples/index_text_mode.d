import std.stdio;
import std.format;
import textmode;

enum W = 640;
enum H = 400;

void main(string[] args) {
    auto pixels = new ubyte[W * H * 4];

    TM_Console console;
    console.palette(TM_paletteVga);
    console.size(80, 50);
    console.outbuf(pixels.ptr, W, H, W * 4);
    TM_Options opt;
    opt.crtEmulation = true;
    console.options(opt);

    with (console) {
        cls();
        println("Hello from text-mode on WASI!");
        save();
        fg(TM_colorRed);
        print("Red text ");
        bg(TM_colorBlue);
        println("on blue");
        render();
    }
}
