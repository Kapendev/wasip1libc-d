import wasip1libc;

void main() {
    testMathValues();
    testMathSpecial();
    testRounding();
    testMemory();
    testStrings();
    testCtype();
    testQsort();
    testAlloc();
    testStubs();

    write(failCount == 0 ? "All tests passed: " : "Some tests failed: ");
    writeNumber(passCount);
    write(" passed, ");
    writeNumber(failCount);
    write(" failed");
    endLine();
}

char[512] lineBuffer;
size_t lineLength;
int passCount;
int failCount;

void write(const(char)[] text) {
    foreach (c; text) {
        if (lineLength < lineBuffer.length - 1) {
            lineBuffer[lineLength] = c;
            lineLength += 1;
        }
    }
}

void writeNumber(long value) {
    char[24] digits = void;
    auto count = 0;
    auto isNegative = value < 0;
    auto rest = isNegative ? -cast(ulong) value : cast(ulong) value;
    do {
        digits[count] = cast(char) ('0' + rest % 10);
        rest /= 10;
        count += 1;
    } while (rest);
    if (isNegative) write("-");
    foreach_reverse (i; 0 .. count) write(digits[i .. i + 1]);
}

void writeHex(ulong value, int digitCount) {
    enum hexDigits = "0123456789ABCDEF";
    write("0x");
    foreach_reverse (i; 0 .. digitCount) {
        auto digit = cast(size_t) ((value >> (i * 4)) & 0xF);
        write(hexDigits[digit .. digit + 1]);
    }
}

void endLine() {
    lineBuffer[lineLength] = 0;
    puts(lineBuffer.ptr);
    lineLength = 0;
}

void fail(const(char)[] what, size_t line) {
    failCount += 1;
    write("FAIL (line ");
    writeNumber(line);
    write("): ");
    write(what);
}

void check(bool isOk, const(char)[] what, size_t line = __LINE__) {
    if (isOk) {
        passCount += 1;
        return;
    }
    fail(what, line);
    endLine();
}

ulong doubleBits(double x) {
    return *cast(ulong*) &x;
}

uint floatBits(float x) {
    return *cast(uint*) &x;
}

// Maps the bits to integers that go up in the same order as the numbers, so a difference counts ulps.
long orderedBits(double x) {
    auto bits = cast(long) doubleBits(x);
    return bits < 0 ? -(bits & long.max) : bits;
}

long orderedBits(float x) {
    auto bits = cast(int) floatBits(x);
    return bits < 0 ? -(bits & int.max) : bits;
}

long ulpDistance(double a, double b) {
    auto distance = orderedBits(a) - orderedBits(b);
    return distance < 0 ? -distance : distance;
}

long ulpDistance(float a, float b) {
    auto distance = orderedBits(a) - orderedBits(b);
    return distance < 0 ? -distance : distance;
}

// Same value. NaN matches NaN, and -0 doesn't match +0.
bool isSame(double a, double b) {
    if (a != a) return b != b;
    return doubleBits(a) == doubleBits(b);
}

bool isSame(float a, float b) {
    if (a != a) return b != b;
    return floatBits(a) == floatBits(b);
}

void checkSame(double got, double expected, const(char)[] what, size_t line = __LINE__) {
    if (isSame(got, expected)) {
        passCount += 1;
        return;
    }
    fail(what, line);
    write(" got ");
    writeHex(doubleBits(got), 16);
    write(", expected ");
    writeHex(doubleBits(expected), 16);
    endLine();
}

void checkSame(float got, float expected, const(char)[] what, size_t line = __LINE__) {
    if (isSame(got, expected)) {
        passCount += 1;
        return;
    }
    fail(what, line);
    write(" got ");
    writeHex(floatBits(got), 8);
    write(", expected ");
    writeHex(floatBits(expected), 8);
    endLine();
}

void checkUlp(double got, double expected, int maxUlp, const(char)[] what, size_t line = __LINE__) {
    auto isOk = isSame(got, expected);
    auto distance = 0L;
    if (!isOk && got == got && expected == expected && got != double.infinity && got != -double.infinity) {
        distance = ulpDistance(got, expected);
        isOk = distance <= maxUlp;
    }
    if (isOk) {
        passCount += 1;
        return;
    }
    fail(what, line);
    write(" got ");
    writeHex(doubleBits(got), 16);
    write(", expected ");
    writeHex(doubleBits(expected), 16);
    if (distance) {
        write(", ");
        writeNumber(distance);
        write(" ulp");
    }
    endLine();
}

void checkUlp(float got, float expected, int maxUlp, const(char)[] what, size_t line = __LINE__) {
    auto isOk = isSame(got, expected);
    auto distance = 0L;
    if (!isOk && got == got && expected == expected && got != float.infinity && got != -float.infinity) {
        distance = ulpDistance(got, expected);
        isOk = distance <= maxUlp;
    }
    if (isOk) {
        passCount += 1;
        return;
    }
    fail(what, line);
    write(" got ");
    writeHex(floatBits(got), 8);
    write(", expected ");
    writeHex(floatBits(expected), 8);
    if (distance) {
        write(", ");
        writeNumber(distance);
        write(" ulp");
    }
    endLine();
}

enum nan = double.nan;
enum inf = double.infinity;
enum nanf = float.nan;
enum inff = float.infinity;

// Normal values against high precision references.
void testMathValues() {
    // sin
    checkUlp(sin(0x1.4f8b588e368f1p-17), 0x1.4f8b588e1e8a2p-17, 2, "sin(1e-05)");
    checkUlp(sin(0x1.0000000000000p-1), 0x1.eaee8744b05f0p-2, 2, "sin(0.5)");
    checkUlp(sin(0x1.91eb851eb851fp-1), 0x1.69e4fd79ac743p-1, 2, "sin(0.785)");
    checkUlp(sin(0x1.0000000000000p+0), 0x1.aed548f090ceep-1, 2, "sin(1.0)");
    checkUlp(sin(-0x1.4cccccccccccdp+0), -0x1.ed577f9c51e4bp-1, 2, "sin(-1.3)");
    checkUlp(sin(0x1.0000000000000p+1), 0x1.d18f6ead1b446p-1, 2, "sin(2.0)");
    checkUlp(sin(0x1.8000000000000p+1), 0x1.210386db6d55bp-3, 2, "sin(3.0)");
    checkUlp(sin(0x1.4000000000000p+3), -0x1.1689ef5f34f52p-1, 2, "sin(10.0)");
    checkUlp(sin(0x1.9000000000000p+6), -0x1.03425b78c4db8p-1, 2, "sin(100.0)");
    checkUlp(sin(0x1.f440000000000p+9), 0x1.fd948c50a7a0dp-1, 2, "sin(1000.5)");
    checkUlp(sin(0x1.81cd6c8b43958p+13), -0x1.687d5890974a5p-1, 2, "sin(12345.678)");
    checkUlp(sinf(0x1.4f8b580000000p-17f), 0x1.4f8b580000000p-17f, 1, "sinf(9.999999747378752e-06)");
    checkUlp(sinf(0x1.0000000000000p-1f), 0x1.eaee880000000p-2f, 1, "sinf(0.5)");
    checkUlp(sinf(0x1.91eb860000000p-1f), 0x1.69e4fe0000000p-1f, 1, "sinf(0.7850000262260437)");
    checkUlp(sinf(0x1.0000000000000p+0f), 0x1.aed5480000000p-1f, 1, "sinf(1.0)");
    checkUlp(sinf(-0x1.4ccccc0000000p+0f), -0x1.ed57800000000p-1f, 1, "sinf(-1.2999999523162842)");
    checkUlp(sinf(0x1.0000000000000p+1f), 0x1.d18f6e0000000p-1f, 1, "sinf(2.0)");
    checkUlp(sinf(0x1.8000000000000p+1f), 0x1.2103860000000p-3f, 1, "sinf(3.0)");
    checkUlp(sinf(0x1.4000000000000p+3f), -0x1.1689f00000000p-1f, 1, "sinf(10.0)");
    checkUlp(sinf(0x1.9000000000000p+6f), -0x1.03425c0000000p-1f, 1, "sinf(100.0)");
    checkUlp(sinf(0x1.f440000000000p+9f), 0x1.fd948c0000000p-1f, 1, "sinf(1000.5)");
    checkUlp(sinf(0x1.81cd6c0000000p+13f), -0x1.6896100000000p-1f, 1, "sinf(12345.677734375)");
    // cos
    checkUlp(cos(0x1.4f8b588e368f1p-17), 0x1.ffffffff920c8p-1, 2, "cos(1e-05)");
    checkUlp(cos(0x1.0000000000000p-1), 0x1.c1528065b7d50p-1, 2, "cos(0.5)");
    checkUlp(cos(0x1.91eb851eb851fp-1), 0x1.6a2ecb934b59ap-1, 2, "cos(0.785)");
    checkUlp(cos(0x1.0000000000000p+0), 0x1.14a280fb5068cp-1, 2, "cos(1.0)");
    checkUlp(cos(-0x1.4cccccccccccdp+0), 0x1.11eb3682a4c5fp-2, 2, "cos(-1.3)");
    checkUlp(cos(0x1.0000000000000p+1), -0x1.aa22657537205p-2, 2, "cos(2.0)");
    checkUlp(cos(0x1.8000000000000p+1), -0x1.fae04be85e5d2p-1, 2, "cos(3.0)");
    checkUlp(cos(0x1.4000000000000p+3), -0x1.ad9ac890c6b1fp-1, 2, "cos(10.0)");
    checkUlp(cos(0x1.9000000000000p+6), 0x1.b981dbf665fdfp-1, 2, "cos(100.0)");
    checkUlp(cos(0x1.f440000000000p+9), 0x1.8dbff75eb664fp-4, 2, "cos(1000.5)");
    checkUlp(cos(0x1.81cd6c8b43958p+13), 0x1.6b94c3bbe24b8p-1, 2, "cos(12345.678)");
    checkUlp(cosf(0x1.4f8b580000000p-17f), 0x1.0000000000000p+0f, 1, "cosf(9.999999747378752e-06)");
    checkUlp(cosf(0x1.0000000000000p-1f), 0x1.c152800000000p-1f, 1, "cosf(0.5)");
    checkUlp(cosf(0x1.91eb860000000p-1f), 0x1.6a2eca0000000p-1f, 1, "cosf(0.7850000262260437)");
    checkUlp(cosf(0x1.0000000000000p+0f), 0x1.14a2800000000p-1f, 1, "cosf(1.0)");
    checkUlp(cosf(-0x1.4ccccc0000000p+0f), 0x1.11eb3a0000000p-2f, 1, "cosf(-1.2999999523162842)");
    checkUlp(cosf(0x1.0000000000000p+1f), -0x1.aa22660000000p-2f, 1, "cosf(2.0)");
    checkUlp(cosf(0x1.8000000000000p+1f), -0x1.fae04c0000000p-1f, 1, "cosf(3.0)");
    checkUlp(cosf(0x1.4000000000000p+3f), -0x1.ad9ac80000000p-1f, 1, "cosf(10.0)");
    checkUlp(cosf(0x1.9000000000000p+6f), 0x1.b981dc0000000p-1f, 1, "cosf(100.0)");
    checkUlp(cosf(0x1.f440000000000p+9f), 0x1.8dbff80000000p-4f, 1, "cosf(1000.5)");
    checkUlp(cosf(0x1.81cd6c0000000p+13f), 0x1.6b7c400000000p-1f, 1, "cosf(12345.677734375)");
    // tan
    checkUlp(tan(0x1.4f8b588e368f1p-17), 0x1.4f8b588e6698ep-17, 3, "tan(1e-05)");
    checkUlp(tan(0x1.0000000000000p-1), 0x1.17b4f5bf3474ap-1, 3, "tan(0.5)");
    checkUlp(tan(0x1.91eb851eb851fp-1), 0x1.ff97aa571156ep-1, 3, "tan(0.785)");
    checkUlp(tan(0x1.0000000000000p+0), 0x1.8eb245cbee3a6p+0, 3, "tan(1.0)");
    checkUlp(tan(-0x1.4cccccccccccdp+0), -0x1.cd11b1696e97ep+1, 3, "tan(-1.3)");
    checkUlp(tan(0x1.8000000000000p+0), 0x1.c33ed50b88777p+3, 3, "tan(1.5)");
    checkUlp(tan(0x1.8000000000000p+1), -0x1.23ef71254b86fp-3, 3, "tan(3.0)");
    checkUlp(tan(0x1.4000000000000p+3), 0x1.4bf5f34be3782p-1, 3, "tan(10.0)");
    checkUlp(tan(0x1.9000000000000p+6), -0x1.2ca74d62b5d38p-1, 3, "tan(100.0)");
    checkUlp(tan(0x1.f440000000000p+9), 0x1.47f9f1c1f4871p+3, 3, "tan(1000.5)");
    checkUlp(tanf(0x1.4f8b580000000p-17f), 0x1.4f8b580000000p-17f, 1, "tanf(9.999999747378752e-06)");
    checkUlp(tanf(0x1.0000000000000p-1f), 0x1.17b4f60000000p-1f, 1, "tanf(0.5)");
    checkUlp(tanf(0x1.91eb860000000p-1f), 0x1.ff97ac0000000p-1f, 1, "tanf(0.7850000262260437)");
    checkUlp(tanf(0x1.0000000000000p+0f), 0x1.8eb2460000000p+0f, 1, "tanf(1.0)");
    checkUlp(tanf(-0x1.4ccccc0000000p+0f), -0x1.cd11ac0000000p+1f, 1, "tanf(-1.2999999523162842)");
    checkUlp(tanf(0x1.8000000000000p+0f), 0x1.c33ed60000000p+3f, 1, "tanf(1.5)");
    checkUlp(tanf(0x1.8000000000000p+1f), -0x1.23ef720000000p-3f, 1, "tanf(3.0)");
    checkUlp(tanf(0x1.4000000000000p+3f), 0x1.4bf5f40000000p-1f, 1, "tanf(10.0)");
    checkUlp(tanf(0x1.9000000000000p+6f), -0x1.2ca74e0000000p-1f, 1, "tanf(100.0)");
    checkUlp(tanf(0x1.f440000000000p+9f), 0x1.47f9f20000000p+3f, 1, "tanf(1000.5)");
    // asin
    checkUlp(asin(-0x1.ccccccccccccdp-1), -0x1.1ea93705fa172p+0, 2, "asin(-0.9)");
    checkUlp(asin(-0x1.0000000000000p-1), -0x1.0c152382d7366p-1, 2, "asin(-0.5)");
    checkUlp(asin(0x1.12e0be826d695p-30), 0x1.12e0be826d695p-30, 2, "asin(1e-09)");
    checkUlp(asin(0x1.999999999999ap-4), 0x1.9a49276037884p-4, 2, "asin(0.1)");
    checkUlp(asin(0x1.0000000000000p-1), 0x1.0c152382d7366p-1, 2, "asin(0.5)");
    checkUlp(asin(0x1.8000000000000p-1), 0x1.b235315c680dcp-1, 2, "asin(0.75)");
    checkUlp(asin(0x1.fae147ae147aep-1), 0x1.6de3c6f33d51dp+0, 2, "asin(0.99)");
    checkUlp(asinf(-0x1.cccccc0000000p-1f), -0x1.1ea9360000000p+0f, 1, "asinf(-0.8999999761581421)");
    checkUlp(asinf(-0x1.0000000000000p-1f), -0x1.0c15240000000p-1f, 1, "asinf(-0.5)");
    checkUlp(asinf(0x1.12e0be0000000p-30f), 0x1.12e0be0000000p-30f, 1, "asinf(9.999999717180685e-10)");
    checkUlp(asinf(0x1.99999a0000000p-4f), 0x1.9a49280000000p-4f, 1, "asinf(0.10000000149011612)");
    checkUlp(asinf(0x1.0000000000000p-1f), 0x1.0c15240000000p-1f, 1, "asinf(0.5)");
    checkUlp(asinf(0x1.8000000000000p-1f), 0x1.b235320000000p-1f, 1, "asinf(0.75)");
    checkUlp(asinf(0x1.fae1480000000p-1f), 0x1.6de3c80000000p+0f, 1, "asinf(0.9900000095367432)");
    // acos
    checkUlp(acos(-0x1.ccccccccccccdp-1), 0x1.586476251e745p+1, 2, "acos(-0.9)");
    checkUlp(acos(-0x1.0000000000000p-1), 0x1.0c152382d7366p+1, 2, "acos(-0.5)");
    checkUlp(acos(0x1.12e0be826d695p-30), 0x1.921fb53ff74e9p+0, 2, "acos(1e-09)");
    checkUlp(acos(0x1.999999999999ap-4), 0x1.787b22ce3f590p+0, 2, "acos(0.1)");
    checkUlp(acos(0x1.0000000000000p-1), 0x1.0c152382d7366p+0, 2, "acos(0.5)");
    checkUlp(acos(0x1.8000000000000p-1), 0x1.720a392c1d955p-1, 2, "acos(0.75)");
    checkUlp(acos(0x1.fae147ae147aep-1), 0x1.21df72882bfd8p-3, 2, "acos(0.99)");
    checkUlp(acosf(-0x1.cccccc0000000p-1f), 0x1.5864760000000p+1f, 1, "acosf(-0.8999999761581421)");
    checkUlp(acosf(-0x1.0000000000000p-1f), 0x1.0c15240000000p+1f, 1, "acosf(-0.5)");
    checkUlp(acosf(0x1.12e0be0000000p-30f), 0x1.921fb60000000p+0f, 1, "acosf(9.999999717180685e-10)");
    checkUlp(acosf(0x1.99999a0000000p-4f), 0x1.787b220000000p+0f, 1, "acosf(0.10000000149011612)");
    checkUlp(acosf(0x1.0000000000000p-1f), 0x1.0c15240000000p+0f, 1, "acosf(0.5)");
    checkUlp(acosf(0x1.8000000000000p-1f), 0x1.720a3a0000000p-1f, 1, "acosf(0.75)");
    checkUlp(acosf(0x1.fae1480000000p-1f), 0x1.21df6a0000000p-3f, 1, "acosf(0.9900000095367432)");
    // atan
    checkUlp(atan(-0x1.9000000000000p+6), -0x1.8f905eb2def22p+0, 2, "atan(-100.0)");
    checkUlp(atan(-0x1.0000000000000p+1), -0x1.1b6e192ebbe44p+0, 2, "atan(-2.0)");
    checkUlp(atan(-0x1.3333333333333p-2), -0x1.2a73a661eaf06p-2, 2, "atan(-0.3)");
    checkUlp(atan(0x1.12e0be826d695p-30), 0x1.12e0be826d695p-30, 2, "atan(1e-09)");
    checkUlp(atan(0x1.999999999999ap-4), 0x1.983e282e2cc4dp-4, 2, "atan(0.1)");
    checkUlp(atan(0x1.999999999999ap-2), 0x1.85a376b677dc0p-2, 2, "atan(0.4)");
    checkUlp(atan(0x1.0000000000000p+0), 0x1.921fb54442d18p-1, 2, "atan(1.0)");
    checkUlp(atan(0x1.8000000000000p+1), 0x1.3fc176b7a8560p+0, 2, "atan(3.0)");
    checkUlp(atan(0x1.2a05f20000000p+33), 0x1.921fb543d4de0p+0, 2, "atan(10000000000.0)");
    checkUlp(atanf(-0x1.9000000000000p+6f), -0x1.8f905e0000000p+0f, 1, "atanf(-100.0)");
    checkUlp(atanf(-0x1.0000000000000p+1f), -0x1.1b6e1a0000000p+0f, 1, "atanf(-2.0)");
    checkUlp(atanf(-0x1.3333340000000p-2f), -0x1.2a73a80000000p-2f, 1, "atanf(-0.30000001192092896)");
    checkUlp(atanf(0x1.12e0be0000000p-30f), 0x1.12e0be0000000p-30f, 1, "atanf(9.999999717180685e-10)");
    checkUlp(atanf(0x1.99999a0000000p-4f), 0x1.983e280000000p-4f, 1, "atanf(0.10000000149011612)");
    checkUlp(atanf(0x1.99999a0000000p-2f), 0x1.85a3780000000p-2f, 1, "atanf(0.4000000059604645)");
    checkUlp(atanf(0x1.0000000000000p+0f), 0x1.921fb60000000p-1f, 1, "atanf(1.0)");
    checkUlp(atanf(0x1.8000000000000p+1f), 0x1.3fc1760000000p+0f, 1, "atanf(3.0)");
    checkUlp(atanf(0x1.2a05f20000000p+33f), 0x1.921fb60000000p+0f, 1, "atanf(10000000000.0)");
    // sinh
    checkUlp(sinh(-0x1.4000000000000p+2), -0x1.28d0166f07374p+6, 2, "sinh(-5.0)");
    checkUlp(sinh(-0x1.3333333333333p-2), -0x1.37d42af54b926p-2, 2, "sinh(-0.3)");
    checkUlp(sinh(0x1.12e0be826d695p-30), 0x1.12e0be826d695p-30, 2, "sinh(1e-09)");
    checkUlp(sinh(0x1.999999999999ap-4), 0x1.9a487337b59b3p-4, 2, "sinh(0.1)");
    checkUlp(sinh(0x1.f5c28f5c28f5cp-2), 0x1.050a6475c00eap-1, 2, "sinh(0.49)");
    checkUlp(sinh(0x1.0000000000000p-1), 0x1.0acd00fe63b97p-1, 2, "sinh(0.5)");
    checkUlp(sinh(0x1.0000000000000p+0), 0x1.2cd9fc44eb982p+0, 2, "sinh(1.0)");
    checkUlp(sinh(0x1.8000000000000p+1), 0x1.40926e70949aep+3, 2, "sinh(3.0)");
    checkUlp(sinh(0x1.4000000000000p+4), 0x1.ceb088b68e804p+27, 2, "sinh(20.0)");
    checkUlp(sinh(0x1.9000000000000p+4), 0x1.0c3d3920962c9p+35, 2, "sinh(25.0)");
    checkUlp(sinh(0x1.5e00000000000p+9), 0x1.d945df4f8ec8ep+1008, 2, "sinh(700.0)");
    checkUlp(sinhf(-0x1.4000000000000p+2f), -0x1.28d0160000000p+6f, 1, "sinhf(-5.0)");
    checkUlp(sinhf(-0x1.3333340000000p-2f), -0x1.37d42c0000000p-2f, 1, "sinhf(-0.30000001192092896)");
    checkUlp(sinhf(0x1.12e0be0000000p-30f), 0x1.12e0be0000000p-30f, 1, "sinhf(9.999999717180685e-10)");
    checkUlp(sinhf(0x1.99999a0000000p-4f), 0x1.9a48740000000p-4f, 1, "sinhf(0.10000000149011612)");
    checkUlp(sinhf(0x1.f5c2900000000p-2f), 0x1.050a640000000p-1f, 1, "sinhf(0.49000000953674316)");
    checkUlp(sinhf(0x1.0000000000000p-1f), 0x1.0acd000000000p-1f, 1, "sinhf(0.5)");
    checkUlp(sinhf(0x1.0000000000000p+0f), 0x1.2cd9fc0000000p+0f, 1, "sinhf(1.0)");
    checkUlp(sinhf(0x1.8000000000000p+1f), 0x1.40926e0000000p+3f, 1, "sinhf(3.0)");
    checkUlp(sinhf(0x1.4000000000000p+4f), 0x1.ceb0880000000p+27f, 1, "sinhf(20.0)");
    checkUlp(sinhf(0x1.9000000000000p+4f), 0x1.0c3d3a0000000p+35f, 1, "sinhf(25.0)");
    // cosh
    checkUlp(cosh(-0x1.4000000000000p+2), 0x1.28d6fcbeff3aap+6, 2, "cosh(-5.0)");
    checkUlp(cosh(-0x1.3333333333333p-2), 0x1.0b9b4e0b6ec4cp+0, 2, "cosh(-0.3)");
    checkUlp(cosh(0x1.12e0be826d695p-30), 0x1.0000000000000p+0, 2, "cosh(1e-09)");
    checkUlp(cosh(0x1.999999999999ap-4), 0x1.0147f40224b38p+0, 2, "cosh(0.1)");
    checkUlp(cosh(0x1.0000000000000p-1), 0x1.20ac1862ae8d0p+0, 2, "cosh(0.5)");
    checkUlp(cosh(0x1.0000000000000p+0), 0x1.8b07551d9f550p+0, 2, "cosh(1.0)");
    checkUlp(cosh(0x1.8000000000000p+1), 0x1.422a497d6185ep+3, 2, "cosh(3.0)");
    checkUlp(cosh(0x1.4000000000000p+4), 0x1.ceb088b68e804p+27, 2, "cosh(20.0)");
    checkUlp(cosh(0x1.9000000000000p+4), 0x1.0c3d3920962c9p+35, 2, "cosh(25.0)");
    checkUlp(cosh(0x1.5e00000000000p+9), 0x1.d945df4f8ec8ep+1008, 2, "cosh(700.0)");
    checkUlp(coshf(-0x1.4000000000000p+2f), 0x1.28d6fc0000000p+6f, 1, "coshf(-5.0)");
    checkUlp(coshf(-0x1.3333340000000p-2f), 0x1.0b9b4e0000000p+0f, 1, "coshf(-0.30000001192092896)");
    checkUlp(coshf(0x1.12e0be0000000p-30f), 0x1.0000000000000p+0f, 1, "coshf(9.999999717180685e-10)");
    checkUlp(coshf(0x1.99999a0000000p-4f), 0x1.0147f40000000p+0f, 1, "coshf(0.10000000149011612)");
    checkUlp(coshf(0x1.0000000000000p-1f), 0x1.20ac180000000p+0f, 1, "coshf(0.5)");
    checkUlp(coshf(0x1.0000000000000p+0f), 0x1.8b07560000000p+0f, 1, "coshf(1.0)");
    checkUlp(coshf(0x1.8000000000000p+1f), 0x1.422a4a0000000p+3f, 1, "coshf(3.0)");
    checkUlp(coshf(0x1.4000000000000p+4f), 0x1.ceb0880000000p+27f, 1, "coshf(20.0)");
    checkUlp(coshf(0x1.9000000000000p+4f), 0x1.0c3d3a0000000p+35f, 1, "coshf(25.0)");
    // tanh
    checkUlp(tanh(-0x1.8000000000000p+1), -0x1.fd77d111a0b00p-1, 2, "tanh(-3.0)");
    checkUlp(tanh(-0x1.999999999999ap-2), -0x1.8511573c242d6p-2, 2, "tanh(-0.4)");
    checkUlp(tanh(0x1.12e0be826d695p-30), 0x1.12e0be826d695p-30, 2, "tanh(1e-09)");
    checkUlp(tanh(0x1.999999999999ap-4), 0x1.983d7795f413ap-4, 2, "tanh(0.1)");
    checkUlp(tanh(0x1.0000000000000p-1), 0x1.d9353d7568af3p-2, 2, "tanh(0.5)");
    checkUlp(tanh(0x1.3333333333333p-1), 0x1.12f8292d2ccfcp-1, 2, "tanh(0.6)");
    checkUlp(tanh(0x1.0000000000000p+1), 0x1.ed9505e1bc3d4p-1, 2, "tanh(2.0)");
    checkUlp(tanh(0x1.4000000000000p+3), 0x1.ffffffdc96f35p-1, 2, "tanh(10.0)");
    checkUlp(tanh(0x1.5000000000000p+4), 0x1.0000000000000p+0, 2, "tanh(21.0)");
    checkUlp(tanhf(-0x1.8000000000000p+1f), -0x1.fd77d20000000p-1f, 1, "tanhf(-3.0)");
    checkUlp(tanhf(-0x1.99999a0000000p-2f), -0x1.8511580000000p-2f, 1, "tanhf(-0.4000000059604645)");
    checkUlp(tanhf(0x1.12e0be0000000p-30f), 0x1.12e0be0000000p-30f, 1, "tanhf(9.999999717180685e-10)");
    checkUlp(tanhf(0x1.99999a0000000p-4f), 0x1.983d780000000p-4f, 1, "tanhf(0.10000000149011612)");
    checkUlp(tanhf(0x1.0000000000000p-1f), 0x1.d9353e0000000p-2f, 1, "tanhf(0.5)");
    checkUlp(tanhf(0x1.3333340000000p-1f), 0x1.12f82a0000000p-1f, 1, "tanhf(0.6000000238418579)");
    checkUlp(tanhf(0x1.0000000000000p+1f), 0x1.ed95060000000p-1f, 1, "tanhf(2.0)");
    checkUlp(tanhf(0x1.4000000000000p+3f), 0x1.0000000000000p+0f, 1, "tanhf(10.0)");
    checkUlp(tanhf(0x1.5000000000000p+4f), 0x1.0000000000000p+0f, 1, "tanhf(21.0)");
    // exp
    checkUlp(exp(-0x1.5e00000000000p+9), 0x1.14f2b0fb9307fp-1010, 2, "exp(-700.0)");
    checkUlp(exp(-0x1.4000000000000p+4), 0x1.1b48655f37267p-29, 2, "exp(-20.0)");
    checkUlp(exp(-0x1.8000000000000p+0), 0x1.c8f87724b5c1dp-3, 2, "exp(-1.5)");
    checkUlp(exp(-0x1.47ae147ae147bp-7), 0x1.fae7cfd2b9cfep-1, 2, "exp(-0.01)");
    checkUlp(exp(0x1.3333333333333p-2), 0x1.599058c8c1a96p+0, 2, "exp(0.3)");
    checkUlp(exp(0x1.0000000000000p+0), 0x1.5bf0a8b145769p+1, 2, "exp(1.0)");
    checkUlp(exp(0x1.4000000000000p+2), 0x1.28d389970338fp+7, 2, "exp(5.0)");
    checkUlp(exp(0x1.9000000000000p+5), 0x1.19103e4080b45p+72, 2, "exp(50.0)");
    checkUlp(exp(0x1.5e00000000000p+9), 0x1.d945df4f8ec8ep+1009, 2, "exp(700.0)");
    checkUlp(expf(-0x1.4000000000000p+4f), 0x1.1b48660000000p-29f, 1, "expf(-20.0)");
    checkUlp(expf(-0x1.8000000000000p+0f), 0x1.c8f8780000000p-3f, 1, "expf(-1.5)");
    checkUlp(expf(-0x1.47ae140000000p-7f), 0x1.fae7d00000000p-1f, 1, "expf(-0.009999999776482582)");
    checkUlp(expf(0x1.3333340000000p-2f), 0x1.59905a0000000p+0f, 1, "expf(0.30000001192092896)");
    checkUlp(expf(0x1.0000000000000p+0f), 0x1.5bf0a80000000p+1f, 1, "expf(1.0)");
    checkUlp(expf(0x1.4000000000000p+2f), 0x1.28d38a0000000p+7f, 1, "expf(5.0)");
    checkUlp(expf(0x1.9000000000000p+5f), 0x1.19103e0000000p+72f, 1, "expf(50.0)");
    // exp2
    checkUlp(exp2(-0x1.0ba0000000000p+10), 0x0.000000000000bp-1022, 2, "exp2(-1070.5)");
    checkUlp(exp2(-0x1.499999999999ap+3), 0x1.9fdf8bcce533ap-11, 2, "exp2(-10.3)");
    checkUlp(exp2(-0x1.0000000000000p-1), 0x1.6a09e667f3bcdp-1, 2, "exp2(-0.5)");
    checkUlp(exp2(0x1.0000000000000p-2), 0x1.306fe0a31b715p+0, 2, "exp2(0.25)");
    checkUlp(exp2(0x1.8000000000000p+1), 0x1.0000000000000p+3, 2, "exp2(3.0)");
    checkUlp(exp2(0x1.5666666666666p+3), 0x1.9fdf8bcce533ap+10, 2, "exp2(10.7)");
    checkUlp(exp2(0x1.ffc0000000000p+9), 0x1.6a09e667f3bcdp+1023, 2, "exp2(1023.5)");
    checkUlp(exp2f(-0x1.49999a0000000p+3f), 0x1.9fdf880000000p-11f, 1, "exp2f(-10.300000190734863)");
    checkUlp(exp2f(-0x1.0000000000000p-1f), 0x1.6a09e60000000p-1f, 1, "exp2f(-0.5)");
    checkUlp(exp2f(0x1.0000000000000p-2f), 0x1.306fe00000000p+0f, 1, "exp2f(0.25)");
    checkUlp(exp2f(0x1.8000000000000p+1f), 0x1.0000000000000p+3f, 1, "exp2f(3.0)");
    checkUlp(exp2f(0x1.5666660000000p+3f), 0x1.9fdf880000000p+10f, 1, "exp2f(10.699999809265137)");
    // log
    checkUlp(log(0x0.0000000000001p-1022), -0x1.74385446d71c3p+9, 2, "log(5e-324)");
    checkUlp(log(0x1.56e1fc2f8f359p-997), -0x1.5963447f87fb5p+9, 2, "log(1e-300)");
    checkUlp(log(0x1.0624dd2f1a9fcp-10), -0x1.ba18a998fffa0p+2, 2, "log(0.001)");
    checkUlp(log(0x1.0000000000000p-1), -0x1.62e42fefa39efp-1, 2, "log(0.5)");
    checkUlp(log(0x1.fae147ae147aep-1), -0x1.495453e6fd4bcp-7, 2, "log(0.99)");
    checkUlp(log(0x1.028f5c28f5c29p+0), 0x1.460d6ccca367cp-7, 2, "log(1.01)");
    checkUlp(log(0x1.0000000000000p+1), 0x1.62e42fefa39efp-1, 2, "log(2.0)");
    checkUlp(log(0x1.4000000000000p+3), 0x1.26bb1bbb55516p+1, 2, "log(10.0)");
    checkUlp(log(0x1.f400000000000p+9), 0x1.ba18a998fffa0p+2, 2, "log(1000.0)");
    checkUlp(log(0x1.7e43c8800759cp+996), 0x1.5963447f87fb5p+9, 2, "log(1e+300)");
    checkUlp(logf(0x1.0624de0000000p-10f), -0x1.ba18aa0000000p+2f, 1, "logf(0.0010000000474974513)");
    checkUlp(logf(0x1.0000000000000p-1f), -0x1.62e4300000000p-1f, 1, "logf(0.5)");
    checkUlp(logf(0x1.fae1480000000p-1f), -0x1.4954400000000p-7f, 1, "logf(0.9900000095367432)");
    checkUlp(logf(0x1.028f5c0000000p+0f), 0x1.460d580000000p-7f, 1, "logf(1.0099999904632568)");
    checkUlp(logf(0x1.0000000000000p+1f), 0x1.62e4300000000p-1f, 1, "logf(2.0)");
    checkUlp(logf(0x1.4000000000000p+3f), 0x1.26bb1c0000000p+1f, 1, "logf(10.0)");
    checkUlp(logf(0x1.f400000000000p+9f), 0x1.ba18aa0000000p+2f, 1, "logf(1000.0)");
    // log2
    checkUlp(log2(0x0.0000000000001p-1022), -0x1.0c80000000000p+10, 2, "log2(5e-324)");
    checkUlp(log2(0x1.56e1fc2f8f359p-997), -0x1.f24a09f1a8b89p+9, 2, "log2(1e-300)");
    checkUlp(log2(0x1.0624dd2f1a9fcp-10), -0x1.3ee7b471b3a95p+3, 2, "log2(0.001)");
    checkUlp(log2(0x1.0000000000000p-1), -0x1.0000000000000p+0, 2, "log2(0.5)");
    checkUlp(log2(0x1.fae147ae147aep-1), -0x1.db1f34d2c386dp-7, 2, "log2(0.99)");
    checkUlp(log2(0x1.028f5c28f5c29p+0), 0x1.d664ecee35b7fp-7, 2, "log2(1.01)");
    checkUlp(log2(0x1.8000000000000p+1), 0x1.95c01a39fbd68p+0, 2, "log2(3.0)");
    checkUlp(log2(0x1.4000000000000p+3), 0x1.a934f0979a371p+1, 2, "log2(10.0)");
    checkUlp(log2(0x1.f400000000000p+9), 0x1.3ee7b471b3a95p+3, 2, "log2(1000.0)");
    checkUlp(log2(0x1.7e43c8800759cp+996), 0x1.f24a09f1a8b89p+9, 2, "log2(1e+300)");
    checkUlp(log2f(0x1.0624de0000000p-10f), -0x1.3ee7b40000000p+3f, 1, "log2f(0.0010000000474974513)");
    checkUlp(log2f(0x1.0000000000000p-1f), -0x1.0000000000000p+0f, 1, "log2f(0.5)");
    checkUlp(log2f(0x1.fae1480000000p-1f), -0x1.db1f160000000p-7f, 1, "log2f(0.9900000095367432)");
    checkUlp(log2f(0x1.028f5c0000000p+0f), 0x1.d664d00000000p-7f, 1, "log2f(1.0099999904632568)");
    checkUlp(log2f(0x1.8000000000000p+1f), 0x1.95c01a0000000p+0f, 1, "log2f(3.0)");
    checkUlp(log2f(0x1.4000000000000p+3f), 0x1.a934f00000000p+1f, 1, "log2f(10.0)");
    checkUlp(log2f(0x1.f400000000000p+9f), 0x1.3ee7b40000000p+3f, 1, "log2f(1000.0)");
    // log10
    checkUlp(log10(0x0.0000000000001p-1022), -0x1.434e6420f4374p+8, 2, "log10(5e-324)");
    checkUlp(log10(0x1.56e1fc2f8f359p-997), -0x1.2c00000000000p+8, 2, "log10(1e-300)");
    checkUlp(log10(0x1.0624dd2f1a9fcp-10), -0x1.8000000000000p+1, 2, "log10(0.001)");
    checkUlp(log10(0x1.0000000000000p-1), -0x1.34413509f79ffp-2, 2, "log10(0.5)");
    checkUlp(log10(0x1.fae147ae147aep-1), -0x1.1e0d4874f92f2p-8, 2, "log10(0.99)");
    checkUlp(log10(0x1.028f5c28f5c29p+0), 0x1.1b349f11fb5bfp-8, 2, "log10(1.01)");
    checkUlp(log10(0x1.0000000000000p+1), 0x1.34413509f79ffp-2, 2, "log10(2.0)");
    checkUlp(log10(0x1.c000000000000p+2), 0x1.b0b0b0b78cc3fp-1, 2, "log10(7.0)");
    checkUlp(log10(0x1.f440000000000p+9), 0x1.80071d1b9ba34p+1, 2, "log10(1000.5)");
    checkUlp(log10(0x1.7e43c8800759cp+996), 0x1.2c00000000000p+8, 2, "log10(1e+300)");
    checkUlp(log10f(0x1.0624de0000000p-10f), -0x1.8000000000000p+1f, 1, "log10f(0.0010000000474974513)");
    checkUlp(log10f(0x1.0000000000000p-1f), -0x1.3441360000000p-2f, 1, "log10f(0.5)");
    checkUlp(log10f(0x1.fae1480000000p-1f), -0x1.1e0d360000000p-8f, 1, "log10f(0.9900000095367432)");
    checkUlp(log10f(0x1.028f5c0000000p+0f), 0x1.1b348e0000000p-8f, 1, "log10f(1.0099999904632568)");
    checkUlp(log10f(0x1.0000000000000p+1f), 0x1.3441360000000p-2f, 1, "log10f(2.0)");
    checkUlp(log10f(0x1.c000000000000p+2f), 0x1.b0b0b00000000p-1f, 1, "log10f(7.0)");
    checkUlp(log10f(0x1.f440000000000p+9f), 0x1.80071e0000000p+1f, 1, "log10f(1000.5)");
    // sqrt
    checkUlp(sqrt(0x0.0000000000001p-1022), 0x1.0000000000000p-537, 1, "sqrt(5e-324)");
    checkUlp(sqrt(0x1.56e1fc2f8f359p-997), 0x1.a2fe76a3f9475p-499, 1, "sqrt(1e-300)");
    checkUlp(sqrt(0x1.0000000000000p-1), 0x1.6a09e667f3bcdp-1, 1, "sqrt(0.5)");
    checkUlp(sqrt(0x1.0000000000000p+1), 0x1.6a09e667f3bcdp+0, 1, "sqrt(2.0)");
    checkUlp(sqrt(0x1.8000000000000p+1), 0x1.bb67ae8584caap+0, 1, "sqrt(3.0)");
    checkUlp(sqrt(0x1.81cd6c8b43958p+13), 0x1.bc71c5eab9ed8p+6, 1, "sqrt(12345.678)");
    checkUlp(sqrt(0x1.7e43c8800759cp+996), 0x1.38d352e5096afp+498, 1, "sqrt(1e+300)");
    checkUlp(sqrtf(0x1.0000000000000p-1f), 0x1.6a09e60000000p-1f, 1, "sqrtf(0.5)");
    checkUlp(sqrtf(0x1.0000000000000p+1f), 0x1.6a09e60000000p+0f, 1, "sqrtf(2.0)");
    checkUlp(sqrtf(0x1.8000000000000p+1f), 0x1.bb67ae0000000p+0f, 1, "sqrtf(3.0)");
    checkUlp(sqrtf(0x1.81cd6c0000000p+13f), 0x1.bc71c60000000p+6f, 1, "sqrtf(12345.677734375)");
    // cbrt
    checkUlp(cbrt(0x0.0000000000001p-1022), 0x1.0000000000000p-358, 1, "cbrt(5e-324)");
    checkUlp(cbrt(0x1.56e1fc2f8f359p-997), 0x1.bff2ee48e0530p-333, 1, "cbrt(1e-300)");
    checkUlp(cbrt(0x1.0624dd2f1a9fcp-10), 0x1.999999999999ap-4, 1, "cbrt(0.001)");
    checkUlp(cbrt(0x1.0000000000000p+1), 0x1.428a2f98d728bp+0, 1, "cbrt(2.0)");
    checkUlp(cbrt(-0x1.b800000000000p+4), -0x1.825b1b6bac03bp+1, 1, "cbrt(-27.5)");
    checkUlp(cbrt(0x1.7e43c8800759cp+996), 0x1.249ad2594c37dp+332, 1, "cbrt(1e+300)");
    checkUlp(cbrtf(0x1.0624de0000000p-10f), 0x1.99999a0000000p-4f, 1, "cbrtf(0.0010000000474974513)");
    checkUlp(cbrtf(0x1.0000000000000p+1f), 0x1.428a300000000p+0f, 1, "cbrtf(2.0)");
    checkUlp(cbrtf(-0x1.b800000000000p+4f), -0x1.825b1c0000000p+1f, 1, "cbrtf(-27.5)");
    // atan2
    checkUlp(atan2(0x1.0000000000000p+0, 0x1.0000000000000p+0), 0x1.921fb54442d18p-1, 2, "atan2(1.0, 1.0)");
    checkUlp(atan2(-0x1.0000000000000p+0, -0x1.0000000000000p+0), -0x1.2d97c7f3321d2p+1, 2, "atan2(-1.0, -1.0)");
    checkUlp(atan2(0x1.0000000000000p+0, -0x1.0000000000000p+1), 0x1.56c6e7397f5aep+1, 2, "atan2(1.0, -2.0)");
    checkUlp(atan2(-0x1.8000000000000p+1, 0x1.0000000000000p-1), -0x1.67d8863bc99bdp+0, 2, "atan2(-3.0, 0.5)");
    checkUlp(atan2(0x1.b7cdfd9d7bdbbp-34, 0x1.0000000000000p+0), 0x1.b7cdfd9d7bdbbp-34, 2, "atan2(1e-10, 1.0)");
    checkUlp(atan2(0x1.4000000000000p+2, -0x1.b7cdfd9d7bdbbp-34), 0x1.921fb54458cf0p+0, 2, "atan2(5.0, -1e-10)");
    checkUlp(atan2(0x1.0000000000000p-1, -0x1.0000000000000p-1), 0x1.2d97c7f3321d2p+1, 2, "atan2(0.5, -0.5)");
    checkUlp(atan2f(0x1.0000000000000p+0f, 0x1.0000000000000p+0f), 0x1.921fb60000000p-1f, 1, "atan2f(1.0, 1.0)");
    checkUlp(atan2f(-0x1.0000000000000p+0f, -0x1.0000000000000p+0f), -0x1.2d97c80000000p+1f, 1, "atan2f(-1.0, -1.0)");
    checkUlp(atan2f(0x1.0000000000000p+0f, -0x1.0000000000000p+1f), 0x1.56c6e80000000p+1f, 1, "atan2f(1.0, -2.0)");
    checkUlp(atan2f(-0x1.8000000000000p+1f, 0x1.0000000000000p-1f), -0x1.67d8860000000p+0f, 1, "atan2f(-3.0, 0.5)");
    checkUlp(atan2f(0x1.b7cdfe0000000p-34f, 0x1.0000000000000p+0f), 0x1.b7cdfe0000000p-34f, 1, "atan2f(1.000000013351432e-10, 1.0)");
    checkUlp(atan2f(0x1.4000000000000p+2f, -0x1.b7cdfe0000000p-34f), 0x1.921fb60000000p+0f, 1, "atan2f(5.0, -1.000000013351432e-10)");
    checkUlp(atan2f(0x1.0000000000000p-1f, -0x1.0000000000000p-1f), 0x1.2d97c80000000p+1f, 1, "atan2f(0.5, -0.5)");
    // pow
    checkUlp(pow(0x1.0000000000000p+1, 0x1.4000000000000p+3), 0x1.0000000000000p+10, 2, "pow(2.0, 10.0)");
    checkUlp(pow(0x1.0000000000000p+1, -0x1.8000000000000p+1), 0x1.0000000000000p-3, 2, "pow(2.0, -3.0)");
    checkUlp(pow(0x1.0000000000000p+1, 0x1.0000000000000p-1), 0x1.6a09e667f3bcdp+0, 2, "pow(2.0, 0.5)");
    checkUlp(pow(0x1.4000000000000p+3, -0x1.0000000000000p+1), 0x1.47ae147ae147bp-7, 2, "pow(10.0, -2.0)");
    checkUlp(pow(0x1.8000000000000p+0, 0x1.4000000000000p+1), 0x1.60b9fd68a4554p+1, 2, "pow(1.5, 2.5)");
    checkUlp(pow(0x1.ccccccccccccdp-1, 0x1.9000000000000p+5), 0x1.51c1fff764631p-8, 2, "pow(0.9, 50.0)");
    checkUlp(pow(-0x1.0000000000000p+1, 0x1.8000000000000p+1), -0x1.0000000000000p+3, 2, "pow(-2.0, 3.0)");
    checkUlp(pow(-0x1.0000000000000p+3, -0x1.8000000000000p+1), -0x1.0000000000000p-9, 2, "pow(-8.0, -3.0)");
    checkUlp(pow(0x1.8000000000000p+1, 0x1.554c985f06f69p-2), 0x1.7133ce7b49eedp+0, 2, "pow(3.0, 0.3333)");
    checkUlp(pow(0x1.00068db8bac71p+0, 0x1.3880000000000p+13), 0x1.5bec34aabbfd3p+1, 2, "pow(1.0001, 10000.0)");
    checkUlp(pow(0x1.e000000000000p+2, -0x1.4000000000000p+0), 0x1.4a03c788c8935p-4, 2, "pow(7.5, -1.25)");
    checkUlp(pow(0x1.58b89f68074cdp-1, -0x1.b028275289d00p+10), 0x1.7739ac03830f7p+986, 2, "pow(0.6732835592735228, -1728.6274000497651)");
    checkUlp(pow(0x1.2e83eeb5e9c60p+3, 0x1.0000000000000p+2), 0x1.f331cddc59b75p+12, 2, "pow(9.45360503702085, 4.0)");
    checkUlp(pow(0x1.199999999999ap+0, 0x1.b580000000000p+12), 0x1.70482352af339p+962, 2, "pow(1.1, 7000.0)");
    checkUlp(pow(0x1.7ae147ae147aep-2, -0x1.5e00000000000p+9), 0x1.0ef7b902a68d6p+1004, 2, "pow(0.37, -700.0)");
    checkUlp(pow(0x1.8000000000000p+0, 0x1.1000000000000p+4), 0x1.eca170c000000p+9, 2, "pow(1.5, 17.0)");
    checkUlp(pow(-0x1.b333333333333p+0, 0x1.f000000000000p+4), -0x1.a9137777bfc96p+23, 2, "pow(-1.7, 31.0)");
    checkUlp(pow(0x1.0000000000000p+1, -0x1.0c80000000000p+10), 0x0.0000000000001p-1022, 2, "pow(2.0, -1074.0)");
    checkUlp(pow(0x1.4000000000000p+3, 0x1.3400000000000p+8), 0x1.1ccf385ebc8a0p+1023, 2, "pow(10.0, 308.0)");
    checkUlp(powf(0x1.0000000000000p+1f, 0x1.4000000000000p+3f), 0x1.0000000000000p+10f, 1, "powf(2.0, 10.0)");
    checkUlp(powf(0x1.0000000000000p+1f, -0x1.8000000000000p+1f), 0x1.0000000000000p-3f, 1, "powf(2.0, -3.0)");
    checkUlp(powf(0x1.0000000000000p+1f, 0x1.0000000000000p-1f), 0x1.6a09e60000000p+0f, 1, "powf(2.0, 0.5)");
    checkUlp(powf(0x1.4000000000000p+3f, -0x1.0000000000000p+1f), 0x1.47ae140000000p-7f, 1, "powf(10.0, -2.0)");
    checkUlp(powf(0x1.8000000000000p+0f, 0x1.4000000000000p+1f), 0x1.60b9fe0000000p+1f, 1, "powf(1.5, 2.5)");
    checkUlp(powf(0x1.cccccc0000000p-1f, 0x1.9000000000000p+5f), 0x1.51c1e20000000p-8f, 1, "powf(0.8999999761581421, 50.0)");
    checkUlp(powf(-0x1.0000000000000p+1f, 0x1.8000000000000p+1f), -0x1.0000000000000p+3f, 1, "powf(-2.0, 3.0)");
    checkUlp(powf(-0x1.0000000000000p+3f, -0x1.8000000000000p+1f), -0x1.0000000000000p-9f, 1, "powf(-8.0, -3.0)");
    checkUlp(powf(0x1.8000000000000p+1f, 0x1.554c980000000p-2f), 0x1.7133ce0000000p+0f, 1, "powf(3.0, 0.33329999446868896)");
    checkUlp(powf(0x1.00068e0000000p+0f, 0x1.3880000000000p+13f), 0x1.5bfafc0000000p+1f, 1, "powf(1.000100016593933, 10000.0)");
    checkUlp(powf(0x1.e000000000000p+2f, -0x1.4000000000000p+0f), 0x1.4a03c80000000p-4f, 1, "powf(7.5, -1.25)");
    checkUlp(powf(0x1.58b8a00000000p-1f, -0x1.b028280000000p+10f), float.infinity, 1, "powf(0.673283576965332, -1728.62744140625)");
    checkUlp(powf(0x1.2e83ee0000000p+3f, 0x1.0000000000000p+2f), 0x1.f331ca0000000p+12f, 1, "powf(9.453604698181152, 4.0)");
    checkUlp(powf(0x1.19999a0000000p+0f, 0x1.b580000000000p+12f), float.infinity, 1, "powf(1.100000023841858, 7000.0)");
    checkUlp(powf(0x1.7ae1480000000p-2f, -0x1.5e00000000000p+9f), float.infinity, 1, "powf(0.3700000047683716, -700.0)");
    checkUlp(powf(0x1.8000000000000p+0f, 0x1.1000000000000p+4f), 0x1.eca1700000000p+9f, 1, "powf(1.5, 17.0)");
    checkUlp(powf(-0x1.b333340000000p+0f, 0x1.f000000000000p+4f), -0x1.a913900000000p+23f, 1, "powf(-1.7000000476837158, 31.0)");
    checkUlp(powf(0x1.0000000000000p+1f, -0x1.0c80000000000p+10f), 0x0.0p+0f, 1, "powf(2.0, -1074.0)");
    checkUlp(powf(0x1.4000000000000p+3f, 0x1.3400000000000p+8f), float.infinity, 1, "powf(10.0, 308.0)");
    // hypot
    checkUlp(hypot(0x1.8000000000000p+1, 0x1.0000000000000p+2), 0x1.4000000000000p+2, 1, "hypot(3.0, 4.0)");
    checkUlp(hypot(0x1.7e43c8800759cp+996, 0x1.7e43c8800759cp+996), 0x1.0e4d50f99b211p+997, 1, "hypot(1e+300, 1e+300)");
    checkUlp(hypot(0x1.56e1fc2f8f359p-997, 0x1.56e1fc2f8f359p-997), 0x1.e4e8d12762225p-997, 1, "hypot(1e-300, 1e-300)");
    checkUlp(hypot(0x1.0000000000000p+0, 0x1.b7cdfd9d7bdbbp-34), 0x1.0000000000000p+0, 1, "hypot(1.0, 1e-10)");
    checkUlp(hypot(0x0.0000000000001p-1022, 0x0.0000000000001p-1022), 0x0.0000000000001p-1022, 1, "hypot(5e-324, 5e-324)");
    checkUlp(hypot(-0x1.0000000000000p+1, 0x1.c000000000000p+2), 0x1.d1ed52076fbe9p+2, 1, "hypot(-2.0, 7.0)");
    checkUlp(hypotf(0x1.8000000000000p+1f, 0x1.0000000000000p+2f), 0x1.4000000000000p+2f, 1, "hypotf(3.0, 4.0)");
    checkUlp(hypotf(0x1.0000000000000p+0f, 0x1.b7cdfe0000000p-34f), 0x1.0000000000000p+0f, 1, "hypotf(1.0, 1.000000013351432e-10)");
    checkUlp(hypotf(-0x1.0000000000000p+1f, 0x1.c000000000000p+2f), 0x1.d1ed520000000p+2f, 1, "hypotf(-2.0, 7.0)");
    // fmod
    checkUlp(fmod(0x1.4000000000000p+3, 0x1.8000000000000p+1), 0x1.0000000000000p+0, 0, "fmod(10.0, 3.0)");
    checkUlp(fmod(-0x1.4000000000000p+3, 0x1.8000000000000p+1), -0x1.0000000000000p+0, 0, "fmod(-10.0, 3.0)");
    checkUlp(fmod(0x1.6000000000000p+2, 0x1.8000000000000p+0), 0x1.0000000000000p+0, 0, "fmod(5.5, 1.5)");
    checkUlp(fmod(0x1.7e43c8800759cp+996, 0x1.c000000000000p+2), 0x1.0000000000000p+0, 0, "fmod(1e+300, 7.0)");
    checkUlp(fmod(0x1.0000000000000p+0, 0x1.56e1fc2f8f359p-997), 0x1.33550b9c24a66p-997, 0, "fmod(1.0, 1e-300)");
    checkUlp(fmod(-0x1.3333333333333p-2, 0x1.999999999999ap-4), -0x1.9999999999998p-4, 0, "fmod(-0.3, 0.1)");
    checkUlp(fmodf(0x1.4000000000000p+3f, 0x1.8000000000000p+1f), 0x1.0000000000000p+0f, 0, "fmodf(10.0, 3.0)");
    checkUlp(fmodf(-0x1.4000000000000p+3f, 0x1.8000000000000p+1f), -0x1.0000000000000p+0f, 0, "fmodf(-10.0, 3.0)");
    checkUlp(fmodf(0x1.6000000000000p+2f, 0x1.8000000000000p+0f), 0x1.0000000000000p+0f, 0, "fmodf(5.5, 1.5)");
    checkUlp(fmodf(-0x1.3333340000000p-2f, 0x1.99999a0000000p-4f), -0x1.0000000000000p-27f, 0, "fmodf(-0.30000001192092896, 0.10000000149011612)");
    // remainder
    checkUlp(remainder(0x1.4000000000000p+3, 0x1.8000000000000p+1), 0x1.0000000000000p+0, 0, "remainder(10.0, 3.0)");
    checkUlp(remainder(-0x1.4000000000000p+3, 0x1.8000000000000p+1), -0x1.0000000000000p+0, 0, "remainder(-10.0, 3.0)");
    checkUlp(remainder(0x1.4000000000000p+2, 0x1.0000000000000p+1), 0x1.0000000000000p+0, 0, "remainder(5.0, 2.0)");
    checkUlp(remainder(0x1.c000000000000p+2, 0x1.0000000000000p+1), -0x1.0000000000000p+0, 0, "remainder(7.0, 2.0)");
    checkUlp(remainder(0x1.7e43c8800759cp+996, 0x1.c000000000000p+2), 0x1.0000000000000p+0, 0, "remainder(1e+300, 7.0)");
    checkUlp(remainder(-0x1.3333333333333p-2, 0x1.999999999999ap-4), 0x1.0000000000000p-55, 0, "remainder(-0.3, 0.1)");
    checkUlp(remainderf(0x1.4000000000000p+3f, 0x1.8000000000000p+1f), 0x1.0000000000000p+0f, 0, "remainderf(10.0, 3.0)");
    checkUlp(remainderf(-0x1.4000000000000p+3f, 0x1.8000000000000p+1f), -0x1.0000000000000p+0f, 0, "remainderf(-10.0, 3.0)");
    checkUlp(remainderf(0x1.4000000000000p+2f, 0x1.0000000000000p+1f), 0x1.0000000000000p+0f, 0, "remainderf(5.0, 2.0)");
    checkUlp(remainderf(0x1.c000000000000p+2f, 0x1.0000000000000p+1f), -0x1.0000000000000p+0f, 0, "remainderf(7.0, 2.0)");
    checkUlp(remainderf(-0x1.3333340000000p-2f, 0x1.99999a0000000p-4f), -0x1.0000000000000p-27f, 0, "remainderf(-0.30000001192092896, 0.10000000149011612)");
    // fma
    checkUlp(fma(0x1.999999999999ap-4, 0x1.4000000000000p+3, -0x1.0000000000000p+0), 0x1.0000000000000p-54, 1, "fma(0.1, 10.0, -1.0)");
    checkUlp(fma(0x1.0000000400000p+0, 0x1.fffffff800000p-1, -0x1.0000000000000p+0), -0x1.0000000000000p-60, 1, "fma(1.0000000009313226, 0.9999999990686774, -1.0)");
    checkUlp(fma(0x1.1ccf385ebc8a0p+1023, 0x1.0000000000000p+1, -0x1.1ccf385ebc8a0p+1023), 0x1.1ccf385ebc8a0p+1023, 1, "fma(1e+308, 2.0, -1e+308)");
    checkUlp(fma(0x1.8000000000000p+1, 0x1.5555555555555p-2, -0x1.0000000000000p+0), -0x1.0000000000000p-54, 1, "fma(3.0, 0.3333333333333333, -1.0)");
    checkUlp(fma(0x1.87e92154ef7acp-665, 0x1.87e92154ef7acp-665, 0x1.56e1fc2f8f359p-997), 0x1.56e1fc2f8f359p-997, 1, "fma(1e-200, 1e-200, 1e-300)");
    checkUlp(fma(0x1.999999999999ap-4, 0x1.999999999999ap-4, -0x1.47ae147ae147bp-7), 0x1.0a3d70a3d70a4p-60, 1, "fma(0.1, 0.1, -0.01)");
    checkUlp(fmaf(0x1.99999a0000000p-4f, 0x1.4000000000000p+3f, -0x1.0000000000000p+0f), 0x1.0000000000000p-26f, 1, "fmaf(0.10000000149011612, 10.0, -1.0)");
    checkUlp(fmaf(0x1.0000000000000p+0f, 0x1.0000000000000p+0f, -0x1.0000000000000p+0f), 0x0.0p+0f, 1, "fmaf(1.0, 1.0, -1.0)");
    checkUlp(fmaf(0x1.8000000000000p+1f, 0x1.5555560000000p-2f, -0x1.0000000000000p+0f), 0x1.0000000000000p-25f, 1, "fmaf(3.0, 0.3333333432674408, -1.0)");
    checkUlp(fmaf(0x1.99999a0000000p-4f, 0x1.99999a0000000p-4f, -0x1.47ae140000000p-7f), 0x1.1eb8520000000p-31f, 1, "fmaf(0.10000000149011612, 0.10000000149011612, -0.009999999776482582)");
}

// Special values: NaN, infinity, signed zero, domain errors and overflow.
void testMathSpecial() {
    checkSame(sin(-0.0), -0.0, "sin(-0)");
    checkSame(sin(inf), nan, "sin(inf)");
    checkSame(cos(nan), nan, "cos(nan)");
    checkSame(cos(-0.0), 1.0, "cos(-0)");
    checkSame(tan(-0.0), -0.0, "tan(-0)");
    checkSame(sinf(-0.0f), -0.0f, "sinf(-0)");
    checkSame(sinf(inff), nanf, "sinf(inf)");
    checkSame(asin(1.1), nan, "asin(1.1)");
    checkSame(acos(-1.0), 0x1.921fb54442d18p+1, "acos(-1) is pi");
    checkSame(acos(1.0), 0.0, "acos(1)");
    checkSame(asin(-0.0), -0.0, "asin(-0)");
    checkSame(atan(-0.0), -0.0, "atan(-0)");
    checkSame(atan(inf), 0x1.921fb54442d18p+0, "atan(inf) is pi / 2");
    checkSame(atan(-inf), -0x1.921fb54442d18p+0, "atan(-inf)");
    checkSame(atan2(0.0, -0.0), 0x1.921fb54442d18p+1, "atan2(0, -0) is pi");
    checkSame(atan2(-0.0, -0.0), -0x1.921fb54442d18p+1, "atan2(-0, -0) is -pi");
    checkSame(atan2(-0.0, 1.0), -0.0, "atan2(-0, 1)");
    checkSame(atan2(inf, -inf), 0x1.2d97c7f3321d2p+1, "atan2(inf, -inf) is 3pi / 4");
    checkSame(atan2(1.0, nan), nan, "atan2(1, nan)");
    checkSame(sinh(-0.0), -0.0, "sinh(-0)");
    checkSame(sinh(-inf), -inf, "sinh(-inf)");
    checkSame(sinh(711.0), inf, "sinh(711) overflows");
    checkSame(sinh(710.0), sinh(710.0) == inf ? 0.0 : sinh(710.0), "sinh(710) doesn't overflow");
    checkSame(cosh(-inf), inf, "cosh(-inf)");
    checkSame(tanh(-0.0), -0.0, "tanh(-0)");
    checkSame(tanh(inf), 1.0, "tanh(inf)");
    checkSame(tanh(-inf), -1.0, "tanh(-inf)");

    checkSame(exp(nan), nan, "exp(nan)");
    checkSame(exp(-inf), 0.0, "exp(-inf)");
    checkSame(exp(inf), inf, "exp(inf)");
    checkSame(exp(710.0), inf, "exp(710) overflows");
    checkSame(exp(-746.0), 0.0, "exp(-746) underflows");
    checkSame(exp(0.0), 1.0, "exp(0)");
    checkSame(expf(89.0f), inff, "expf(89) overflows");
    checkSame(exp2(3.0), 8.0, "exp2(3) is exact");
    checkSame(exp2(-1074.0), 0x1p-1074, "exp2(-1074) is the smallest subnormal");
    checkSame(exp2f(10.0f), 1024.0f, "exp2f(10) is exact");
    checkSame(log(1.0), 0.0, "log(1)");
    checkSame(log(0.0), -inf, "log(0)");
    checkSame(log(-0.0), -inf, "log(-0)");
    checkSame(log(-1.0), nan, "log(-1)");
    checkSame(log(inf), inf, "log(inf)");
    checkSame(log2(8.0), 3.0, "log2(8) is exact");
    checkSame(log2(0x1p-1074), -1074.0, "log2 of the smallest subnormal");
    checkSame(log2f(1024.0f), 10.0f, "log2f(1024) is exact");
    checkSame(log10(0.0), -inf, "log10(0)");
    checkSame(logf(-1.0f), nanf, "logf(-1)");

    checkSame(sqrt(-1.0), nan, "sqrt(-1)");
    checkSame(sqrt(-0.0), -0.0, "sqrt(-0)");
    checkSame(sqrt(inf), inf, "sqrt(inf)");
    checkSame(sqrt(4.0), 2.0, "sqrt(4) is exact");
    checkSame(sqrtf(9.0f), 3.0f, "sqrtf(9) is exact");
    checkSame(cbrt(-8.0), -2.0, "cbrt(-8)");
    checkSame(cbrt(-0.0), -0.0, "cbrt(-0)");
    checkSame(cbrt(-inf), -inf, "cbrt(-inf)");

    checkSame(pow(2.0, 0.0), 1.0, "pow(x, 0)");
    checkSame(pow(nan, 0.0), 1.0, "pow(nan, 0)");
    checkSame(pow(1.0, nan), 1.0, "pow(1, nan)");
    checkSame(pow(-1.0, inf), 1.0, "pow(-1, inf)");
    checkSame(pow(-8.0, 1.0 / 3), nan, "pow(-8, 1/3)");
    checkSame(pow(0.0, -1.0), inf, "pow(0, -1)");
    checkSame(pow(-0.0, -1.0), -inf, "pow(-0, -1)");
    checkSame(pow(-0.0, 3.0), -0.0, "pow(-0, 3)");
    checkSame(pow(-inf, 3.0), -inf, "pow(-inf, 3)");
    checkSame(pow(-inf, 0.5), inf, "pow(-inf, 0.5)");
    checkSame(pow(-inf, -3.0), -0.0, "pow(-inf, -3)");
    checkSame(pow(0.5, inf), 0.0, "pow(0.5, inf)");
    checkSame(pow(2.0, -inf), 0.0, "pow(2, -inf)");
    checkSame(pow(3.0, 2.0), 9.0, "pow(3, 2) is exact");
    checkSame(pow(-2.0, 5.0), -32.0, "pow(-2, 5) is exact");
    checkSame(pow(2.0, 1024.0), inf, "pow(2, 1024) overflows");
    checkUlp(pow(1e78, -4.0), 0x0.0002f201d49fbp-1022, 1, "pow(1e78, -4) is subnormal, not 0");

    checkSame(fmod(-4.0, 2.0), -0.0, "fmod(-4, 2)");
    checkSame(fmod(5.0, inf), 5.0, "fmod(5, inf)");
    checkSame(fmod(inf, 2.0), nan, "fmod(inf, 2)");
    checkSame(fmod(1.0, 0.0), nan, "fmod(1, 0)");
    checkSame(remainder(-4.0, 2.0), -0.0, "remainder(-4, 2)");
    checkSame(remainder(-0.0, 1.0), -0.0, "remainder(-0, 1)");
    checkSame(remainder(5.0, 2.0), 1.0, "remainder(5, 2) rounds 2.5 to 2");
    checkSame(remainder(7.0, 2.0), -1.0, "remainder(7, 2) rounds 3.5 to 4");
    checkSame(remainder(1.0, 0.0), nan, "remainder(1, 0)");
    checkSame(hypot(inf, nan), inf, "hypot(inf, nan)");
    checkSame(hypot(nan, 1.0), nan, "hypot(nan, 1)");
    checkSame(hypotf(3.0f, 4.0f), 5.0f, "hypotf(3, 4)");

    checkSame(fma(0.0, 5.0, -0.0), 0.0, "fma(0, 5, -0)");
    checkSame(fma(-0.5, 0x1p-1074, 0.0), -0.0, "fma(-0.5, smallest, 0) keeps the sign");
    checkSame(fma(inf, 0.0, 1.0), nan, "fma(inf, 0, 1)");
    checkSame(fma(1e308, 10.0, -inf), -inf, "fma(1e308, 10, -inf)");
}

void testRounding() {
    checkSame(floor(-0.5), -1.0, "floor(-0.5)");
    checkSame(floor(-0.0), -0.0, "floor(-0)");
    checkSame(floor(0.5), 0.0, "floor(0.5)");
    checkSame(floor(-0x1p60), -0x1p60, "floor(big)");
    checkSame(floor(nan), nan, "floor(nan)");
    checkSame(floorf(-2.5f), -3.0f, "floorf(-2.5)");
    checkSame(ceil(-0.5), -0.0, "ceil(-0.5) is -0");
    checkSame(ceil(0.5), 1.0, "ceil(0.5)");
    checkSame(ceilf(-0.5f), -0.0f, "ceilf(-0.5) is -0");
    checkSame(round(2.5), 3.0, "round(2.5)");
    checkSame(round(-2.5), -3.0, "round(-2.5) rounds away from zero");
    checkSame(round(-0.4), -0.0, "round(-0.4) is -0");
    checkSame(round(0.49999999999999994), 0.0, "round(0.49999999999999994) is 0");
    checkSame(round(4503599627370495.5), 4503599627370496.0, "round(2^52 - 0.5)");
    checkSame(roundf(-2.5f), -3.0f, "roundf(-2.5)");
    checkSame(roundf(0.49999997f), 0.0f, "roundf(0.49999997) is 0");
    checkSame(trunc(-2.7), -2.0, "trunc(-2.7)");
    checkSame(trunc(-0.3), -0.0, "trunc(-0.3) is -0");
    checkSame(truncf(2.7f), 2.0f, "truncf(2.7)");
    checkSame(rint(2.5), 2.0, "rint(2.5) rounds to even");
    checkSame(rint(3.5), 4.0, "rint(3.5) rounds to even");
    checkSame(rint(-0.4), -0.0, "rint(-0.4) is -0");
    checkSame(rintf(-2.5f), -2.0f, "rintf(-2.5)");
    check(lround(2.5) == 3, "lround(2.5)");
    check(lround(-2.5) == -3, "lround(-2.5)");
    check(lround(1e20) == CLong.min, "lround(1e20) is out of range");
    check(lround(nan) == CLong.min, "lround(nan)");
    check(llround(-1e10) == -10_000_000_000L, "llround(-1e10)");
    check(llround(1e30) == long.min, "llround(1e30) is out of range");
    check(lrint(2.5) == 2, "lrint(2.5)");
    check(llrint(-3.5) == -4, "llrint(-3.5)");
    check(lroundf(-1.5f) == -2, "lroundf(-1.5)");

    checkSame(fabs(-0.0), 0.0, "fabs(-0) is +0");
    checkSame(fabs(-inf), inf, "fabs(-inf)");
    checkSame(fabsf(-3.0f), 3.0f, "fabsf(-3)");
    checkSame(copysign(3.0, -0.0), -3.0, "copysign(3, -0)");
    checkSame(copysignf(-3.0f, 1.0f), 3.0f, "copysignf(-3, 1)");
    checkSame(fmin(nan, 1.0), 1.0, "fmin(nan, 1)");
    checkSame(fmin(1.0, nan), 1.0, "fmin(1, nan)");
    checkSame(fmin(0.0, -0.0), -0.0, "fmin(0, -0)");
    checkSame(fmax(-0.0, 0.0), 0.0, "fmax(-0, 0)");
    checkSame(fmax(-1.0, -2.0), -1.0, "fmax(-1, -2)");
    checkSame(fminf(2.0f, 1.0f), 1.0f, "fminf(2, 1)");
    checkSame(fmaxf(nanf, 1.0f), 1.0f, "fmaxf(nan, 1)");

    checkSame(ldexp(1.0, 10), 1024.0, "ldexp(1, 10)");
    checkSame(ldexp(1.0, -1074), 0x1p-1074, "ldexp(1, -1074)");
    checkSame(ldexp(1.0, 1024), inf, "ldexp(1, 1024) overflows");
    checkSame(ldexp(1.0, int.min), 0.0, "ldexp(1, int.min)");
    checkSame(ldexp(0x1p-1074, 2000), 0x1p926, "ldexp(smallest, 2000)");
    checkSame(scalbnf(3.0f, 2), 12.0f, "scalbnf(3, 2)");
    int exponent = void;
    checkSame(frexp(8.0, &exponent), 0.5, "frexp(8) mantissa");
    check(exponent == 4, "frexp(8) exponent");
    checkSame(frexp(-0x1p-1074, &exponent), -0.5, "frexp(-smallest) mantissa");
    check(exponent == -1073, "frexp(-smallest) exponent");
    checkSame(frexp(inf, &exponent), inf, "frexp(inf)");
    checkSame(frexpf(3.0f, &exponent), 0.75f, "frexpf(3) mantissa");
    check(exponent == 2, "frexpf(3) exponent");
    double integer = void;
    checkSame(modf(-3.25, &integer), -0.25, "modf(-3.25) fraction");
    checkSame(integer, -3.0, "modf(-3.25) integer");
    checkSame(modf(-3.0, &integer), -0.0, "modf(-3) fraction is -0");
    checkSame(modf(inf, &integer), 0.0, "modf(inf) fraction");
    checkSame(integer, inf, "modf(inf) integer");
    float integerf = void;
    checkSame(modff(2.5f, &integerf), 0.5f, "modff(2.5) fraction");
    checkSame(integerf, 2.0f, "modff(2.5) integer");
}

void testMemory() {
    ubyte[64] buffer = void;
    foreach (i; 0 .. 64) buffer[i] = cast(ubyte) i;

    // Overlapping moves in both directions.
    memmove(buffer.ptr + 4, buffer.ptr, 20);
    auto isOk = true;
    foreach (i; 0 .. 20) if (buffer[4 + i] != i) isOk = false;
    check(isOk, "memmove forward overlap");
    foreach (i; 0 .. 64) buffer[i] = cast(ubyte) i;
    memmove(buffer.ptr, buffer.ptr + 4, 20);
    isOk = true;
    foreach (i; 0 .. 20) if (buffer[i] != i + 4) isOk = false;
    check(isOk, "memmove backward overlap");
    check(memmove(buffer.ptr, buffer.ptr, 0) == buffer.ptr, "memmove returns dest");

    ubyte[64] other = void;
    check(memcpy(other.ptr, buffer.ptr, 64) == other.ptr, "memcpy returns dest");
    check(memcmp(other.ptr, buffer.ptr, 64) == 0, "memcpy copies");
    check(memset(other.ptr, 0xAB, 10) == other.ptr, "memset returns dest");
    isOk = true;
    foreach (i; 0 .. 10) if (other[i] != 0xAB) isOk = false;
    check(isOk && other[10] == buffer[10], "memset fills only count bytes");
    memset(other.ptr, 0x1FF, 1);
    check(other[0] == 0xFF, "memset uses the low byte");

    ubyte[3] a = [1, 2, 200];
    ubyte[3] b = [1, 2, 100];
    check(memcmp(a.ptr, b.ptr, 3) > 0, "memcmp compares as unsigned");
    check(memcmp(a.ptr, b.ptr, 2) == 0, "memcmp stops at count");

    auto text = "hello world";
    check(memchr(text.ptr, 'o', 11) == text.ptr + 4, "memchr finds the first match");
    check(memchr(text.ptr, 'o', 4) == null, "memchr stops at count");
    check(memchr(text.ptr, 'h' + 256, 11) == text.ptr, "memchr uses the low byte");
}

void testStrings() {
    check(strlen("") == 0, "strlen empty");
    check(strlen("hello") == 5, "strlen");
    check(strnlen("hello", 3) == 3, "strnlen stops at max");
    check(strnlen("hi", 10) == 2, "strnlen stops at the end");

    check(strcmp("abc", "abc") == 0, "strcmp equal");
    check(strcmp("abc", "abd") < 0, "strcmp less");
    check(strcmp("abd", "abc") > 0, "strcmp greater");
    check(strcmp("ab", "abc") < 0, "strcmp prefix is less");
    check(strcmp("", "a") < 0, "strcmp empty is less");
    check(strcmp("\xff", "\x01") > 0, "strcmp compares as unsigned");
    check(strncmp("abcx", "abcy", 3) == 0, "strncmp stops at count");
    check(strncmp("abcx", "abcy", 4) < 0, "strncmp");
    check(strncmp("ab", "ab", 10) == 0, "strncmp stops at the end");
    check(strncmp("a", "b", 0) == 0, "strncmp with 0");

    auto text = "abcabc";
    check(strchr(text.ptr, 'b') == text.ptr + 1, "strchr");
    check(strchr(text.ptr, 'z') == null, "strchr missing");
    check(strchr(text.ptr, 0) == text.ptr + 6, "strchr finds the terminator");
    check(strrchr(text.ptr, 'b') == text.ptr + 4, "strrchr");
    check(strrchr(text.ptr, 'z') == null, "strrchr missing");
    check(strrchr(text.ptr, 0) == text.ptr + 6, "strrchr finds the terminator");
    check(strstr(text.ptr, "ca") == text.ptr + 2, "strstr");
    check(strstr(text.ptr, "") == text.ptr, "strstr with empty needle");
    check(strstr(text.ptr, "abd") == null, "strstr missing");
    check(strstr("aaab".ptr, "aab") != null, "strstr after a partial match");
    check(strstr("ab".ptr, "abc") == null, "strstr needle longer than haystack");

    char[16] buffer = void;
    memset(buffer.ptr, 'X', 16);
    check(strcpy(buffer.ptr, "hi") == buffer.ptr && strcmp(buffer.ptr, "hi") == 0, "strcpy");
    check(strcat(buffer.ptr, "!!") == buffer.ptr && strcmp(buffer.ptr, "hi!!") == 0, "strcat");
    memset(buffer.ptr, 'X', 16);
    strncpy(buffer.ptr, "ab", 5);
    check(buffer[0] == 'a' && buffer[1] == 'b' && buffer[2] == 0 && buffer[4] == 0 && buffer[5] == 'X', "strncpy pads with zeros");
    memset(buffer.ptr, 'X', 16);
    strncpy(buffer.ptr, "abcdef", 3);
    check(buffer[2] == 'c' && buffer[3] == 'X', "strncpy doesn't add a terminator when full");
    strcpy(buffer.ptr, "ab");
    strncat(buffer.ptr, "cdef", 2);
    check(strcmp(buffer.ptr, "abcd") == 0, "strncat stops at count and terminates");
}

void testCtype() {
    auto isOk = true;
    foreach (c; -1 .. 256) {
        auto isDigit = c >= '0' && c <= '9';
        auto isUpper = c >= 'A' && c <= 'Z';
        auto isLower = c >= 'a' && c <= 'z';
        auto isSpace = c == ' ' || (c >= '\t' && c <= '\r');
        auto isPrint = c >= 32 && c < 127;
        if ((isdigit(c) != 0) != isDigit) isOk = false;
        if ((isupper(c) != 0) != isUpper) isOk = false;
        if ((islower(c) != 0) != isLower) isOk = false;
        if ((isalpha(c) != 0) != (isUpper || isLower)) isOk = false;
        if ((isalnum(c) != 0) != (isUpper || isLower || isDigit)) isOk = false;
        if ((isxdigit(c) != 0) != (isDigit || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) isOk = false;
        if ((isspace(c) != 0) != isSpace) isOk = false;
        if ((isblank(c) != 0) != (c == ' ' || c == '\t')) isOk = false;
        if ((isprint(c) != 0) != isPrint) isOk = false;
        if ((isgraph(c) != 0) != (isPrint && c != ' ')) isOk = false;
        if ((iscntrl(c) != 0) != ((c >= 0 && c < 32) || c == 127)) isOk = false;
        if ((ispunct(c) != 0) != (isPrint && c != ' ' && !isUpper && !isLower && !isDigit)) isOk = false;
        if (toupper(c) != (isLower ? c - 32 : c)) isOk = false;
        if (tolower(c) != (isUpper ? c + 32 : c)) isOk = false;
    }
    check(isOk, "ctype functions for every value from -1 to 255");
}

uint randomState = 12345;

uint nextRandom() {
    randomState = randomState * 1103515245 + 12345;
    return randomState >> 8;
}

struct Item3 {
    ubyte[3] data;
}

struct Item12 {
    int key;
    int[2] payload;
}

extern(C) @trusted nothrow @nogc {
    int compareInt(const(void)* a, const(void)* b) {
        auto x = *cast(const(int)*) a;
        auto y = *cast(const(int)*) b;
        return x < y ? -1 : x > y;
    }

    int compareLong(const(void)* a, const(void)* b) {
        auto x = *cast(const(long)*) a;
        auto y = *cast(const(long)*) b;
        return x < y ? -1 : x > y;
    }

    int compareItem3(const(void)* a, const(void)* b) {
        return memcmp(a, b, 3);
    }

    int compareItem12(const(void)* a, const(void)* b) {
        return compareInt(a, b);
    }
}

int[3000] qsortInts;
long[3000] qsortLongs;
Item3[1000] qsortItems3;
Item12[1000] qsortItems12;

void testQsort() {
    static size_t[10] counts = [0, 1, 2, 3, 12, 13, 14, 100, 1000, 3000];
    foreach (pattern; 0 .. 5) {
        foreach (count; counts) {
            long sumBefore = 0;
            foreach (i; 0 .. count) {
                int value = void;
                switch (pattern) {
                    case 0:  value = cast(int) nextRandom(); break;  // Random.
                    case 1:  value = cast(int) i; break;             // Sorted.
                    case 2:  value = cast(int) (count - i); break;   // Reversed.
                    case 3:  value = 7; break;                       // All equal.
                    default: value = nextRandom() % 4; break;        // Few distinct values.
                }
                qsortInts[i] = value;
                qsortLongs[i] = value * 1000003L;
                sumBefore += value;
            }
            qsort(qsortInts.ptr, count, int.sizeof, &compareInt);
            qsort(qsortLongs.ptr, count, long.sizeof, &compareLong);
            auto isSorted = true;
            long sumAfter = 0;
            foreach (i; 0 .. count) {
                if (i > 0 && (qsortInts[i - 1] > qsortInts[i] || qsortLongs[i - 1] > qsortLongs[i])) isSorted = false;
                if (qsortLongs[i] != qsortInts[i] * 1000003L) isSorted = false;
                sumAfter += qsortInts[i];
            }
            check(isSorted && sumBefore == sumAfter, "qsort ints and longs, every pattern and count");
        }
    }

    foreach (count; [0, 1, 7, 20, 1000]) {
        foreach (i; 0 .. count) {
            qsortItems3[i].data = [cast(ubyte) nextRandom(), cast(ubyte) nextRandom(), cast(ubyte) nextRandom()];
            qsortItems12[i] = Item12(nextRandom() % 50, [cast(int) i, -cast(int) i]);
        }
        qsort(qsortItems3.ptr, count, Item3.sizeof, &compareItem3);
        qsort(qsortItems12.ptr, count, Item12.sizeof, &compareItem12);
        auto isSorted = true;
        foreach (i; 1 .. count) {
            if (memcmp(&qsortItems3[i - 1], &qsortItems3[i], 3) > 0) isSorted = false;
            if (qsortItems12[i - 1].key > qsortItems12[i].key) isSorted = false;
        }
        foreach (i; 0 .. count) {
            if (qsortItems12[i].payload[0] != -qsortItems12[i].payload[1]) isSorted = false; // Items moved whole.
        }
        check(isSorted, "qsort 3 and 12 byte items");
    }
    qsort(null, 10, 4, &compareInt); // Shouldn't crash.
}

void testAlloc() {
    auto a = cast(ubyte*) malloc(100);
    check(a != null, "malloc");
    check((cast(size_t) a) % 16 == 0, "malloc is 16 byte aligned");
    foreach (i; 0 .. 100) a[i] = cast(ubyte) i;
    auto b = cast(ubyte*) malloc(1);
    check((cast(size_t) b) % 16 == 0 && b != a, "second malloc");

    auto c = cast(ubyte*) realloc(a, 5000);
    auto isOk = c != null;
    foreach (i; 0 .. 100) if (c[i] != i) isOk = false;
    check(isOk, "realloc keeps the contents");
    auto d = cast(ubyte*) realloc(c, 10);
    check(d != null && d[9] == 9, "realloc smaller");

    auto e = cast(ubyte*) calloc(1000, 4);
    isOk = e != null;
    foreach (i; 0 .. 4000) if (e[i] != 0) isOk = false;
    check(isOk, "calloc zeroes");
    check(calloc(size_t.max / 2, 4) == null, "calloc overflow returns null");
    check(realloc(null, 8) != null, "realloc null works like malloc");
    free(null);
    free(b);
}

void testStubs() {
    auto text = "123abc";
    char* end = null;
    check(strtol(text.ptr, &end, 10) == 0 && end == text.ptr, "strtol stub parses nothing");
    check(strtoul(text.ptr, &end, 10) == 0 && end == text.ptr, "strtoul stub parses nothing");
    check(strtod(text.ptr, &end) == 0 && end == text.ptr, "strtod stub parses nothing");
    check(strtof(text.ptr, &end) == 0 && end == text.ptr, "strtof stub parses nothing");
    check(atoi(text.ptr) == 0, "atoi stub");
    check(atof(text.ptr) == 0, "atof stub");
}
