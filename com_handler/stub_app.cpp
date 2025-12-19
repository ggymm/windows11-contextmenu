// Simple placeholder application for Sparse Package
// This program doesn't need to do anything - it just provides
// an application identity for the Sparse Package

#include <windows.h>

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
    // Show info message
    MessageBoxW(NULL,
        L"Context Menu Tool\n\n"
        L"This is a Windows 11 context menu extension.\n\n"
        L"Right-click on any file or folder to see 'My Right-Click Menu'.",
        L"Context Menu Tool",
        MB_OK | MB_ICONINFORMATION);

    return 0;
}
