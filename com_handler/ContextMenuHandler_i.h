#pragma once
#include <initguid.h>

// Define the GUIDs with __declspec(selectany) to avoid multiple definition errors
// This allows the GUID to be defined in a header file

// {F9A8B7C6-D5E4-3F2A-1B0C-9E8D7A6F5E4D}
__declspec(selectany) extern const GUID CLSID_ContextMenuHandler =
    { 0xf9a8b7c6, 0xd5e4, 0x3f2a, { 0x1b, 0x0c, 0x9e, 0x8d, 0x7a, 0x6f, 0x5e, 0x4d } };

// {F9A8B7C6-D5E4-3F2A-1B0C-9E8D7A6F5E4D}
__declspec(selectany) extern const GUID LIBID_ContextMenuHandlerLib =
    { 0xf9a8b7c6, 0xd5e4, 0x3f2a, { 0x1b, 0x0c, 0x9e, 0x8d, 0x7a, 0x6f, 0x5e, 0x4d } };
