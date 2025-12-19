#pragma once

#include "resource.h"
#include "ContextMenuHandler_i.h"

class CContextMenuHandlerModule : public ATL::CAtlDllModuleT<CContextMenuHandlerModule>
{
public:
    DECLARE_LIBID(LIBID_ContextMenuHandlerLib)
};

extern class CContextMenuHandlerModule _AtlModule;
