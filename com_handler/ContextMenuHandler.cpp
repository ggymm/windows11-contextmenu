#include "pch.h"
#include "ContextMenuHandler.h"
#include <shlwapi.h>
#include <strsafe.h>
#include <pathcch.h>

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "pathcch.lib")

CContextMenuHandler::CContextMenuHandler()
{
}

CContextMenuHandler::~CContextMenuHandler()
{
}

// IExplorerCommand::GetTitle
IFACEMETHODIMP CContextMenuHandler::GetTitle(IShellItemArray* psiItemArray, LPWSTR* ppszName)
{
    return SHStrDup(L"My Right-Click Menu", ppszName);
}

// IExplorerCommand::GetIcon
IFACEMETHODIMP CContextMenuHandler::GetIcon(IShellItemArray* psiItemArray, LPWSTR* ppszIcon)
{
    // Get the path to the Rust executable
    WCHAR szModulePath[MAX_PATH];
    if (GetModuleFileNameW(NULL, szModulePath, ARRAYSIZE(szModulePath)))
    {
        WCHAR szDirPath[MAX_PATH];
        StringCchCopyW(szDirPath, ARRAYSIZE(szDirPath), szModulePath);
        PathCchRemoveFileSpec(szDirPath, ARRAYSIZE(szDirPath));

        WCHAR szExePath[MAX_PATH];
        PathCchCombine(szExePath, ARRAYSIZE(szExePath), szDirPath, L"contextmenu.exe");

        // Icon format: "path,index"
        WCHAR szIcon[MAX_PATH + 10];
        StringCchPrintfW(szIcon, ARRAYSIZE(szIcon), L"%s,0", szExePath);
        return SHStrDup(szIcon, ppszIcon);
    }

    // Fallback to shell32 icon
    return SHStrDup(L"shell32.dll,-16769", ppszIcon);
}

// IExplorerCommand::GetToolTip
IFACEMETHODIMP CContextMenuHandler::GetToolTip(IShellItemArray* psiItemArray, LPWSTR* ppszInfotip)
{
    return SHStrDup(L"Click to execute custom action", ppszInfotip);
}

// IExplorerCommand::GetCanonicalName
IFACEMETHODIMP CContextMenuHandler::GetCanonicalName(GUID* pguidCommandName)
{
    *pguidCommandName = CLSID_ContextMenuHandler;
    return S_OK;
}

// IExplorerCommand::GetState
IFACEMETHODIMP CContextMenuHandler::GetState(IShellItemArray* psiItemArray, BOOL fOkToBeSlow, EXPCMDSTATE* pCmdState)
{
    *pCmdState = ECS_ENABLED;
    return S_OK;
}

// IExplorerCommand::Invoke
IFACEMETHODIMP CContextMenuHandler::Invoke(IShellItemArray* psiItemArray, IBindCtx* pbc)
{
    std::vector<std::wstring> paths;
    HRESULT hr = GetSelectedFilePaths(psiItemArray, paths);
    if (SUCCEEDED(hr))
    {
        hr = ExecuteRustProgram(paths);
    }
    return hr;
}

// IExplorerCommand::GetFlags
IFACEMETHODIMP CContextMenuHandler::GetFlags(EXPCMDFLAGS* pFlags)
{
    *pFlags = ECF_DEFAULT;
    return S_OK;
}

// IExplorerCommand::EnumSubCommands
IFACEMETHODIMP CContextMenuHandler::EnumSubCommands(IEnumExplorerCommand** ppEnum)
{
    *ppEnum = nullptr;
    return E_NOTIMPL;
}

// IObjectWithSelection::SetSelection
IFACEMETHODIMP CContextMenuHandler::SetSelection(IShellItemArray* psia)
{
    m_psia = psia;
    return S_OK;
}

// IObjectWithSelection::GetSelection
IFACEMETHODIMP CContextMenuHandler::GetSelection(REFIID riid, void** ppv)
{
    return m_psia ? m_psia->QueryInterface(riid, ppv) : E_FAIL;
}

// Helper: Get selected file paths
HRESULT CContextMenuHandler::GetSelectedFilePaths(IShellItemArray* psiItemArray, std::vector<std::wstring>& paths)
{
    if (!psiItemArray)
        return E_INVALIDARG;

    DWORD count;
    HRESULT hr = psiItemArray->GetCount(&count);
    if (FAILED(hr))
        return hr;

    for (DWORD i = 0; i < count; i++)
    {
        CComPtr<IShellItem> psi;
        hr = psiItemArray->GetItemAt(i, &psi);
        if (SUCCEEDED(hr))
        {
            LPWSTR pszPath;
            hr = psi->GetDisplayName(SIGDN_FILESYSPATH, &pszPath);
            if (SUCCEEDED(hr))
            {
                paths.push_back(pszPath);
                CoTaskMemFree(pszPath);
            }
        }
    }

    return S_OK;
}

// Helper: Execute action - Show message box directly
HRESULT CContextMenuHandler::ExecuteRustProgram(const std::vector<std::wstring>& paths)
{
    // Build message with all selected paths
    std::wstring message;

    if (paths.size() == 1)
    {
        message = L"You clicked on:\n\n" + paths[0];
    }
    else
    {
        message = L"You clicked on " + std::to_wstring(paths.size()) + L" items:\n\n";
        for (const auto& path : paths)
        {
            message += path + L"\n";
        }
    }

    // Show message box
    MessageBoxW(NULL, message.c_str(), L"My Right-Click Menu", MB_OK | MB_ICONINFORMATION);

    return S_OK;
}
