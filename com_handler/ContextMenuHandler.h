#pragma once
#include <windows.h>
#include <shobjidl_core.h>
#include <shlobj.h>
#include <atlbase.h>
#include <atlcom.h>
#include <string>
#include <vector>
#include "ContextMenuHandler_i.h"

class ATL_NO_VTABLE CContextMenuHandler :
    public CComObjectRootEx<CComSingleThreadModel>,
    public CComCoClass<CContextMenuHandler, &CLSID_ContextMenuHandler>,
    public IExplorerCommand,
    public IObjectWithSelection
{
public:
    CContextMenuHandler();
    ~CContextMenuHandler();

    DECLARE_NOT_AGGREGATABLE(CContextMenuHandler)
    DECLARE_PROTECT_FINAL_CONSTRUCT()

    BEGIN_COM_MAP(CContextMenuHandler)
        COM_INTERFACE_ENTRY(IExplorerCommand)
        COM_INTERFACE_ENTRY(IObjectWithSelection)
    END_COM_MAP()

    // IExplorerCommand
    IFACEMETHODIMP GetTitle(IShellItemArray* psiItemArray, LPWSTR* ppszName);
    IFACEMETHODIMP GetIcon(IShellItemArray* psiItemArray, LPWSTR* ppszIcon);
    IFACEMETHODIMP GetToolTip(IShellItemArray* psiItemArray, LPWSTR* ppszInfotip);
    IFACEMETHODIMP GetCanonicalName(GUID* pguidCommandName);
    IFACEMETHODIMP GetState(IShellItemArray* psiItemArray, BOOL fOkToBeSlow, EXPCMDSTATE* pCmdState);
    IFACEMETHODIMP Invoke(IShellItemArray* psiItemArray, IBindCtx* pbc);
    IFACEMETHODIMP GetFlags(EXPCMDFLAGS* pFlags);
    IFACEMETHODIMP EnumSubCommands(IEnumExplorerCommand** ppEnum);

    // IObjectWithSelection
    IFACEMETHODIMP SetSelection(IShellItemArray* psia);
    IFACEMETHODIMP GetSelection(REFIID riid, void** ppv);

private:
    CComPtr<IShellItemArray> m_psia;
    HRESULT GetSelectedFilePaths(IShellItemArray* psiItemArray, std::vector<std::wstring>& paths);
    HRESULT ExecuteRustProgram(const std::vector<std::wstring>& paths);
};
