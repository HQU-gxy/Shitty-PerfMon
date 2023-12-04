#pragma once

struct DriveUsageInfo
{
    char *driveLetter;
    unsigned long long totalSizeMB;
    unsigned long long freeSpaceMB;
};

extern "C" _declspec(dllexport) int getDriveUsage(DriveUsageInfo *driveUsageList);

