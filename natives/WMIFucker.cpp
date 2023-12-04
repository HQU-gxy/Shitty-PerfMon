#define _WIN32_DCOM

#include <iostream>
#include <Wbemidl.h>
#include <WMIFucker.h>

#pragma comment(lib, "wbemuuid.lib")

using namespace std;

IWbemRefresher *pRefresher = NULL;
IWbemHiPerfEnum *pEnumProcess = NULL;
IWbemHiPerfEnum *pEnumCPU = NULL;
IWbemObjectAccess **apEnumAccessProcess = NULL;
IWbemObjectAccess **apEnumAccessCPU = NULL;

ProcessInfo *processes = nullptr;
uint8_t *coreUsages = nullptr;

char *wcharToString(wchar_t *pWCStrKey)
{
    int pSize = WideCharToMultiByte(CP_OEMCP, 0, pWCStrKey, wcslen(pWCStrKey), NULL, 0, NULL, NULL);
    char *pCStrKey = new char[pSize + 1];
    WideCharToMultiByte(CP_OEMCP, 0, pWCStrKey, wcslen(pWCStrKey), pCStrKey, pSize, NULL, NULL);
    pCStrKey[pSize] = '\0';
    // string pKey = pCStrKey;
    return pCStrKey;
}

bool init()
{
    // To add error checking,
    // check returned HRESULT below where collected.
    BSTR bstrNameSpace = NULL;
    IWbemLocator *pWbemLocator = NULL;
    IWbemConfigureRefresher *pConfigProcess = NULL;
    IWbemConfigureRefresher *pConfigCPU = NULL;
    IWbemServices *pNameSpace = NULL;

    long lID = 0;

    CoInitializeEx(NULL, COINIT_MULTITHREADED);

    if (FAILED(CoInitializeSecurity(
            NULL,
            -1,
            NULL,
            NULL,
            RPC_C_AUTHN_LEVEL_NONE,
            RPC_C_IMP_LEVEL_IMPERSONATE,
            NULL, EOAC_NONE, 0)))
        return false;

    if (FAILED(CoCreateInstance(
            CLSID_WbemLocator,
            NULL,
            CLSCTX_INPROC_SERVER,
            IID_IWbemLocator,
            (void **)&pWbemLocator)))
        return false;

    // Connect to the desired namespace.
    bstrNameSpace = SysAllocString(L"\\\\.\\root\\cimv2");
    if (NULL == bstrNameSpace)
        return false;
    if (FAILED(pWbemLocator->ConnectServer(
            bstrNameSpace,
            NULL, // User name
            NULL, // Password
            NULL, // Locale
            0L,   // Security flags
            NULL, // Authority
            NULL, // Wbem context
            &pNameSpace)))
        return false;
    pWbemLocator->Release();
    pWbemLocator = NULL;
    SysFreeString(bstrNameSpace);
    bstrNameSpace = NULL;

    if (FAILED(CoCreateInstance(
            CLSID_WbemRefresher,
            NULL,
            CLSCTX_INPROC_SERVER,
            IID_IWbemRefresher,
            (void **)&pRefresher)))
        return false;

    if (FAILED(pRefresher->QueryInterface(
            IID_IWbemConfigureRefresher,
            (void **)&pConfigProcess)))
        return false;
    if (FAILED(pRefresher->QueryInterface(
            IID_IWbemConfigureRefresher,
            (void **)&pConfigCPU)))
        return false;

    // Add an enumerator to the refresher.
    if (FAILED(pConfigProcess->AddEnum(
            pNameSpace,
            L"Win32_PerfRawData_PerfProc_Process",
            0,
            NULL,
            &pEnumProcess,
            &lID)))
        return false;

    pConfigProcess->Release();
    pConfigProcess = NULL;

    if (FAILED(pConfigCPU->AddEnum(
            pNameSpace,
            L"Win32_PerfFormattedData_PerfOS_Processor",
            0,
            NULL,
            &pEnumCPU,
            &lID)))
        return false;
    pConfigCPU->Release();
    pConfigCPU = NULL;

    return true;
}

bool getCpuUsage(CPUInfo *pInfo)
{
    static long lPercentProcessorTimeHandle = 0;
    static long lNameHandle = 0;

    static bool firstTime = true;

    DWORD dwNumObjects = 0;
    static DWORD dwNumReturned = 0;

    if (coreUsages)
    {
        delete[] coreUsages;
        coreUsages = nullptr;
    }

    pRefresher->Refresh(0L);

    auto hr = pEnumCPU->GetObjects(0L, dwNumObjects, apEnumAccessCPU, &dwNumReturned);
    if (hr == WBEM_E_BUFFER_TOO_SMALL &&
        dwNumReturned > dwNumObjects)
    {
        apEnumAccessCPU = new IWbemObjectAccess *[dwNumReturned];
        if (NULL == apEnumAccessCPU)
            return false;
        SecureZeroMemory(apEnumAccessCPU,
                         dwNumReturned * sizeof(IWbemObjectAccess *));
        dwNumObjects = dwNumReturned;

        if (FAILED(pEnumCPU->GetObjects(0L,
                                        dwNumObjects,
                                        apEnumAccessCPU,
                                        &dwNumReturned)))
            return false;
    }
    else if (hr == WBEM_S_NO_ERROR)
        return false;

    if (firstTime)
    {
        firstTime = false;
        CIMTYPE PercentProcessorTimeType;
        CIMTYPE ProcessNameType;

        if (FAILED(apEnumAccessCPU[0]->GetPropertyHandle(
                L"PercentProcessorTime",
                &PercentProcessorTimeType,
                &lPercentProcessorTimeHandle)))
            return false;

        if (FAILED(apEnumAccessCPU[0]->GetPropertyHandle(
                L"Name",
                &ProcessNameType,
                &lNameHandle)))
            return false;
    }

    coreUsages = new uint8_t[dwNumReturned];
    for (DWORD i = 0; i < dwNumReturned; i++)
    {
        DWORD dwPercentProcessorTime;
        apEnumAccessCPU[i]->ReadDWORD(
            lPercentProcessorTimeHandle,
            &dwPercentProcessorTime);

        wchar_t cpuName[100];
        long len;
        apEnumAccessCPU[i]->ReadPropertyValue(
            lNameHandle,
            100,
            &len,
            (byte *)cpuName);

        char *name = wcharToString(cpuName);
        if (strcmp(name, "_Total") == 0)
            pInfo->totalUsage = (uint8_t)dwPercentProcessorTime;
        else
            coreUsages[i] = (uint8_t)dwPercentProcessorTime;

        delete name;
    }
    pInfo->coreUsages = coreUsages;
    pInfo->nCores = (uint8_t)dwNumReturned - 1;
    return true;
}

int getProcesses(ProcessInfo **plist)
{
    static long lVirtualBytesHandle = 0;
    static long lIDProcessHandle = 0;
    static long lProcessNameHandle = 0;
    static bool firstTime = true;

    DWORD dwNumObjects = 0;
    static DWORD dwNumReturned = 0;

    if (processes)
    {
        for (DWORD i = 0; i < dwNumReturned; i++)
        {
            delete processes[i].name;
        }
        delete[] processes;
    }

    pRefresher->Refresh(0L);

    // If the buffer was not big enough,
    // allocate a bigger buffer and retry.
    auto hr = pEnumProcess->GetObjects(0L, dwNumObjects,
                                       apEnumAccessProcess,
                                       &dwNumReturned);
    if (hr == WBEM_E_BUFFER_TOO_SMALL &&
        dwNumReturned > dwNumObjects)
    {
        apEnumAccessProcess = new IWbemObjectAccess *[dwNumReturned];
        if (NULL == apEnumAccessProcess)
            return 0;
        SecureZeroMemory(apEnumAccessProcess,
                         dwNumReturned * sizeof(IWbemObjectAccess *));
        dwNumObjects = dwNumReturned;

        if (FAILED(pEnumProcess->GetObjects(0L,
                                            dwNumObjects,
                                            apEnumAccessProcess,
                                            &dwNumReturned)))
            return 0;
    }
    else if (hr == WBEM_S_NO_ERROR)
        return 0;

    if (firstTime)
    {
        firstTime = false;
        CIMTYPE VirtualBytesType;
        CIMTYPE ProcessHandleType;
        CIMTYPE ProcessNameType;

        if (FAILED(apEnumAccessProcess[0]->GetPropertyHandle(
                L"VirtualBytes",
                &VirtualBytesType,
                &lVirtualBytesHandle)))
            return 0;
        if (FAILED(apEnumAccessProcess[0]->GetPropertyHandle(
                L"IDProcess",
                &ProcessHandleType,
                &lIDProcessHandle)))
            return 0;
        if (FAILED(apEnumAccessProcess[0]->GetPropertyHandle(
                L"Name",
                &ProcessNameType,
                &lProcessNameHandle)))
            return 0;
    }

    processes = new ProcessInfo[dwNumReturned];
    for (DWORD i = 0; i < dwNumReturned; i++)
    {
        wchar_t processName[1024];
        long len;
        DWORD dwVirtualBytes;
        DWORD dwIDProcess;

        apEnumAccessProcess[i]->ReadDWORD(
            lVirtualBytesHandle,
            &dwVirtualBytes);

        apEnumAccessProcess[i]->ReadDWORD(
            lIDProcessHandle,
            &dwIDProcess);

        apEnumAccessProcess[i]->ReadPropertyValue(
            lProcessNameHandle,
            1024,
            &len,
            (byte *)processName);

        processes[i].name = wcharToString(processName);
        processes[i].pid = dwIDProcess;
        processes[i].bytes = dwVirtualBytes;

        // wprintf(L"Process: %s ID %lu is using %lu bytes\n", processName, dwIDProcess, dwVirtualBytes);

        // Done with the object
        apEnumAccessProcess[i]->Release();
        apEnumAccessProcess[i] = NULL;
    }

    if (NULL != apEnumAccessProcess)
    {
        delete[] apEnumAccessProcess;
        apEnumAccessProcess = NULL;
    }
    *plist = processes;
    return dwNumReturned;
}


long long getMemUsage()
{
    MEMORYSTATUSEX memState;
    memState.dwLength = sizeof(memState);
    GlobalMemoryStatusEx(&memState);
    return memState.ullTotalPhys - memState.ullAvailPhys;
}

int main()
{
    init();
    cout << "Memory load: " << getMemUsage() << endl;

    CPUInfo cpuInfo;
    getCpuUsage(&cpuInfo);
    for (int i = 0; i < cpuInfo.nCores; i++)
    {
        cout << "CPU " << i << " load: " << (int)cpuInfo.coreUsages[i] << endl;
        cout << "Total CPU load: " << (int)cpuInfo.totalUsage << endl;
    }
}