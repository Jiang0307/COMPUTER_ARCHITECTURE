#include <stdio.h>
#include <stdint.h>

static inline int my_clz(uint32_t x)
{
    int r = 0, c;
    c = (x < 0x00010000) << 4;
    r += c;
    x <<= c; // off 16

    c = (x < 0x01000000) << 3;
    r += c;
    x <<= c; // off 8

    c = (x < 0x10000000) << 2;
    r += c;
    x <<= c; // off 4

    c = (x >> (32 - 4 - 1)) & 0x1e;
    return r + ((0x55af >> c) & 3);
}

int Log2(int n)
{
    return 31 - my_clz(n);
}

int main()
{
    printf("log2(2) = %d\n", Log2(4));       // 2
    printf("log2(127) = %d\n", Log2(10));    // 3.1029... --> 3
    printf("log2(1024) = %d\n", Log2(1025)); // 10.0014... --> 10
    return 0;
}