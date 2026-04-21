/*
 * FreeRDPBridge.h
 *
 * Bridging-header skeleton for the FreeRDP XCFramework integration.
 *
 * This header is guarded by FREERDP_AVAILABLE so the project builds even
 * when the FreeRDP binary target is absent (e.g., local developer builds
 * without the XCFramework). The real bridge will forward C symbols from
 * FreeRDP headers (freerdp/freerdp.h etc.) to Swift via the module map
 * once the Scripts/build-freerdp.sh pipeline produces the XCFramework.
 */

#ifndef EVERYTERM_FREERDP_BRIDGE_H
#define EVERYTERM_FREERDP_BRIDGE_H

#ifdef FREERDP_AVAILABLE

/*
 * TODO: Include FreeRDP public headers when the XCFramework is linked.
 *   #include <freerdp/freerdp.h>
 *   #include <freerdp/client.h>
 *   #include <freerdp/gdi/gdi.h>
 *
 * TODO: Declare any C shim functions needed to adapt FreeRDP callbacks
 *       to Swift (e.g., event loop pumping, context allocation helpers).
 */

#endif /* FREERDP_AVAILABLE */

#endif /* EVERYTERM_FREERDP_BRIDGE_H */
