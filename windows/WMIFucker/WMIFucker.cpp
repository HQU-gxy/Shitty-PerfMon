#define _WIN32_DCOM

#include <iostream>
#include <WMIFucker.h>
#include <string>
using namespace std;

#include <Wbemidl.h>
#pragma comment(lib, "wbemuuid.lib")

IWbemRefresher *pRefresher = NULL;
IWbemHiPerfEnum *pEnum = NULL;
IWbemObjectAccess **apEnumAccess = NULL;

ProcessInfo *processes;

bool firstTime = true;

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
    IWbemConfigureRefresher *pConfig = NULL;
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
            (void **)&pConfig)))
        return false;

    // Add an enumerator to the refresher.
    if (FAILED(pConfig->AddEnum(
            pNameSpace,
            L"Win32_PerfRawData_PerfProc_Process",
            0,
            NULL,
            &pEnum,
            &lID)))
        return false;
    pConfig->Release();
    pConfig = NULL;

    return true;
}
// Get a property handle for the VirtualBytes property.

// Refresh the object ten times and retrieve the value.
int getProcesses(ProcessInfo **plist)
{
    static long lVirtualBytesHandle = 0;
    static long lIDProcessHandle = 0;
    static long lProcessNameHandle = 0;

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

    if (FAILED(pRefresher->Refresh(0L)))
        return 0;

    // If the buffer was not big enough,
    // allocate a bigger buffer and retry.
    auto hr = pEnum->GetObjects(0L, dwNumObjects,
                                apEnumAccess,
                                &dwNumReturned);
    if (hr == WBEM_E_BUFFER_TOO_SMALL &&
        dwNumReturned > dwNumObjects)
    {
        apEnumAccess = new IWbemObjectAccess *[dwNumReturned];
        if (NULL == apEnumAccess)
            return 0;
        SecureZeroMemory(apEnumAccess,
                         dwNumReturned * sizeof(IWbemObjectAccess *));
        dwNumObjects = dwNumReturned;

        if (FAILED(pEnum->GetObjects(0L,
                                     dwNumObjects,
                                     apEnumAccess,
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

        if (FAILED(apEnumAccess[0]->GetPropertyHandle(
                L"VirtualBytes",
                &VirtualBytesType,
                &lVirtualBytesHandle)))
            return 0;
        if (FAILED(apEnumAccess[0]->GetPropertyHandle(
                L"IDProcess",
                &ProcessHandleType,
                &lIDProcessHandle)))
            return 0;
        if (FAILED(apEnumAccess[0]->GetPropertyHandle(
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

        apEnumAccess[i]->ReadDWORD(
            lVirtualBytesHandle,
            &dwVirtualBytes);

        apEnumAccess[i]->ReadDWORD(
            lIDProcessHandle,
            &dwIDProcess);

        apEnumAccess[i]->ReadPropertyValue(
            lProcessNameHandle,
            1024,
            &len,
            (byte *)processName);

        processes[i].name = wcharToString(processName);
        processes[i].pid = dwIDProcess;
        processes[i].bytes = dwVirtualBytes;

        // wprintf(L"Process: %s ID %lu is using %lu bytes\n", processName, dwIDProcess, dwVirtualBytes);

        // Done with the object
        apEnumAccess[i]->Release();
        apEnumAccess[i] = NULL;
    }

    if (NULL != apEnumAccess)
    {
        delete[] apEnumAccess;
        apEnumAccess = NULL;
    }
    *plist = processes;
    return dwNumReturned;
}

// void cleanup()
// {
//     if (NULL != bstrNameSpace)
//     {
//         SysFreeString(bstrNameSpace);
//     }

//     if (NULL != apEnumAccess)
//     {
//         delete[] apEnumAccess;
//     }
//     if (NULL != pWbemLocator)
//     {
//         pWbemLocator->Release();
//     }
//     if (NULL != pNameSpace)
//     {
//         pNameSpace->Release();
//     }
//     if (NULL != pEnum)
//     {
//         pEnum->Release();
//     }
//     if (NULL != pConfig)
//     {
//         pConfig->Release();
//     }
//     if (NULL != pRefresher)
//     {
//         pRefresher->Release();
//     }

//     CoUninitialize();
// }

int main()
{
    init();
    for (int a = 0; a < 10; a++)
    {
        ProcessInfo *pList = nullptr;
        int np = getProcesses(&pList);
        for (int i = 0; i < np; i++)
        {
            cout << pList[i].name << ", PID: " << pList[i].pid << " is eating " << pList[i].bytes << " bytes of mem.\n";
        }
        Sleep(1);
    }
}