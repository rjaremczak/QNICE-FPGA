/*
    Test multiple "parallel" file read operations to challenge
    the FAT32 lib's internal caching mechanims.

    Used to discover and fix the "read multiple files parallel" bug
    in the FAT32 lib.

    by sy2002 in November 2016
*/

#if __STDC_VERSION__ != 199901L
#error This program needs C99 to compile. Use the -c99 VBCC switch.
#endif

#include <stdio.h>

int main()
{
    FILE* file1 = fopen("file1.txt", "r");
    FILE* file2 = fopen("file2.txt", "r");
    FILE* file3 = fopen("file3.txt", "r");

    const int MAXCHARS = 20;

    for (int i = 0; i < MAXCHARS; i++)
    {
        char read1[3], read2[3], read3[3];
        read1[2] = read2[2] = read3[2] = 0;

        int res1 = fread(read1, 2, 1, file1);
        int res2 = fread(read2, 2, 1, file2);
        int res3 = fread(read3, 2, 1, file3);

        if (res1 == res2 == res3 == 1)
            printf("1:%s\t2:%s\t3:%s\n", read1, read2, read3);
        else
        {
            puts("Error reading one of the files. Terminated.");
            return -1;
        }
    }

    fclose(file1);
    fclose(file2);
    fclose(file3);
}