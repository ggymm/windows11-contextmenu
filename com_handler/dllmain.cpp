#include "pch.h"
#include "framework.h"
#include "resource.h"
#include "ContextMenuHandler_i.h"
#include "dllmain.h"
#include "ContextMenuHandler.h"

CContextMenuHandlerModule _AtlModule;

// Simple class factory implementation
class CContextMenuHandlerFactory : public IClassFactory
{
private:
    LONG m_cRef;

public:
    CContextMenuHandlerFactory() : m_cRef(1) {}

    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv)
    {
        if (riid == IID_IUnknown || riid == IID_IClassFactory)
        {
            *ppv = static_cast<IClassFactory*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }

    STDMETHODIMP_(ULONG) AddRef()
    {
        return InterlockedIncrement(&m_cRef);
    }

    STDMETHODIMP_(ULONG) Release()
    {
        LONG cRef = InterlockedDecrement(&m_cRef);
        if (cRef == 0)
            delete this;
        return cRef;
    }

    // IClassFactory
    STDMETHODIMP CreateInstance(IUnknown* pUnkOuter, REFIID riid, void** ppv)
    {
        if (pUnkOuter != nullptr)
            return CLASS_E_NOAGGREGATION;

        CComObject<CContextMenuHandler>* pObj = nullptr;
        HRESULT hr = CComObject<CContextMenuHandler>::CreateInstance(&pObj);
        if (FAILED(hr))
            return hr;

        pObj->AddRef();
        hr = pObj->QueryInterface(riid, ppv);
        pObj->Release();
        return hr;
    }

    STDMETHODIMP LockServer(BOOL fLock)
    {
        if (fLock)
            _AtlModule.Lock();
        else
            _AtlModule.Unlock();
        return S_OK;
    }
};

// DLL Entry Point
extern "C" BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
    return _AtlModule.DllMain(dwReason, lpReserved);
}

// Used to determine whether the DLL can be unloaded by OLE
STDAPI DllCanUnloadNow(void)
{
    return _AtlModule.DllCanUnloadNow();
}

// Returns a class factory to create an object of the requested type
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID* ppv)
{
    if (rclsid == CLSID_ContextMenuHandler)
    {
        CContextMenuHandlerFactory* pFactory = new CContextMenuHandlerFactory();
        if (pFactory == nullptr)
            return E_OUTOFMEMORY;

        HRESULT hr = pFactory->QueryInterface(riid, ppv);
        pFactory->Release();
        return hr;
    }
    return CLASS_E_CLASSNOTAVAILABLE;
}

// DllRegisterServer - Not used with Sparse Package
STDAPI DllRegisterServer(void)
{
    return S_OK;
}

// DllUnregisterServer - Not used with Sparse Package
STDAPI DllUnregisterServer(void)
{
    return S_OK;
}
