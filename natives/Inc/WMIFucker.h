#pragma once

struct ProcessInfo
{
    char *name;
    uint32_t pid;
    uint32_t bytes;
};

struct CPUInfo
{
    uint8_t nCores;
    uint8_t totalUsage;
    uint8_t *coreUsages;
};

extern "C" _declspec(dllexport) bool init();
extern "C" _declspec(dllexport) int getProcesses(ProcessInfo **pplist);
extern "C" _declspec(dllexport) long long getMemUsage();
extern "C" _declspec(dllexport) bool getCpuUsage(CPUInfo *pInfo);
