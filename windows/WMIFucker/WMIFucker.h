#pragma once

struct ProcessInfo
{
    char *name;
    uint32_t pid;
    uint32_t bytes;
};

extern "C" _declspec(dllexport) bool init();
extern "C" _declspec(dllexport) int getProcesses(ProcessInfo **pplist);
