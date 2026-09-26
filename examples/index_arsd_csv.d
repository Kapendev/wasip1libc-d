import arsd.csv;
import std.stdio;

enum rawCsv = `name,hp,alive
Alex,82,true
Mira,0,false
"Quoted, Name",15,true
`;

void main() {
    foreach (row; readCsv(rawCsv)) {
        if (row.length < 3) continue;
        writeln(row[0], " hp=", row[1], " alive=", row[2]);
    }
}
