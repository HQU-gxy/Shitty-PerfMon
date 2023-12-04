#include <iostream>
#include <windows.h>
#include "DriveUsageInfo.h"

using namespace std;

int getDriveUsage(DriveUsageInfo *driveUsageList)
{
    char buffer[300];
    char *pBuffer = buffer;
    GetLogicalDriveStrings(300, buffer);
    bool eof = false;
    int nDrives = 0;
    do
    {
        int i = 0;
        while (*pBuffer)
            driveUsageList[nDrives].driveLetter[i++] = *(pBuffer++);
        driveUsageList[nDrives].driveLetter[i] = '\0';

        i = 0;
        nDrives++;
        if (!*(++pBuffer))
            eof = true;
    } while (!eof);
    for (int i = 0; i < nDrives; i++)
    {
        ULARGE_INTEGER freeBytesAvailable, totalNumberOfBytes, totalNumberOfFreeBytes;
        GetDiskFreeSpaceEx(driveUsageList[i].driveLetter, &freeBytesAvailable, &totalNumberOfBytes, &totalNumberOfFreeBytes);
        driveUsageList[i].totalSizeMB = totalNumberOfBytes.QuadPart / (1024 * 1024);
        driveUsageList[i].freeSpaceMB = totalNumberOfFreeBytes.QuadPart / (1024 * 1024);
    }
    return nDrives;
}
