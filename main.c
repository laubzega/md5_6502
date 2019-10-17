#include <stdio.h>
#include <time.h>

void md5_init(void);
void __fastcall__ md5_next_block_fastcall(unsigned char size, unsigned char *data);
void md5_finalize(void);
extern unsigned char md5_hash[16];
void __fastcall__ exo_init_decruncher(unsigned char *src);

unsigned char data[64]= "123456789012345678901234567890123456789012345678901234567890123";
unsigned char ref[16]={0x5e, 0x43, 0xd5, 0x50, 0xcf, 0x52, 0xd2, 0x9f,
                       0x50, 0x60, 0xe8, 0x72, 0xd5, 0xf2, 0x62, 0x8d};

int main()
{
    int i, blocks = 256;
    int t_total, secs, tens;
    int t_start = clock();
    char ok = 1;
    data[63] = 0x0a;    // so that cc65 does not translate it to C64's newline.

    printf("\nMD5 for 6502 by Laubzega/WFMH'19\n");
    printf("Hashing MD5");
    md5_init();
    for (i = 0; i < blocks; i++) {
        if ((i & 0x01f) == 0)
            printf(".");
        md5_next_block_fastcall(64, data);
    }

    md5_finalize();

    printf("\nNeeded: ");
    for (i = 0; i < 16; i++)
        printf("%02x", ref[i]);

    printf("Hashed: ");
    for (i = 0; i < 16; i++)
        printf("%02x", md5_hash[i]);


    for (i = 0; i < 16; i++)
        if (ref[i] != md5_hash[i]) {
            ok = 0;
            break;
        }

    printf(ok ? "MATCH!\n" : "FAIL!?\n");

    t_total = clock() - t_start;
    secs = t_total / CLOCKS_PER_SEC;
    tens = 100 * (t_total - secs * CLOCKS_PER_SEC) / CLOCKS_PER_SEC;
    printf("\nTime: %d.%02d s (%ld bytes/s)\n", secs, tens, CLOCKS_PER_SEC * (64L * blocks) / t_total );

    return 0;
}
