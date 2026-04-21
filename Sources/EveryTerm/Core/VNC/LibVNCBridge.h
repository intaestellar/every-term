/*
 * LibVNCBridge.h
 *
 * Bridging-header skeleton for the LibVNCClient XCFramework integration.
 *
 * This header is guarded by LIBVNC_AVAILABLE so the project builds even
 * when the LibVNCClient binary target is absent (e.g., local developer
 * builds without the XCFramework). The real bridge will forward C symbols
 * from rfb/rfbclient.h to Swift via the module map once the
 * Scripts/build-libvncclient.sh pipeline produces the XCFramework.
 */

#ifndef EVERYTERM_LIBVNC_BRIDGE_H
#define EVERYTERM_LIBVNC_BRIDGE_H

#ifdef LIBVNC_AVAILABLE

/*
 * TODO: Include LibVNCClient public headers when the XCFramework is linked.
 *   #include <rfb/rfbclient.h>
 *
 * TODO: Declare any C shim functions needed to adapt LibVNCClient
 *       callbacks to Swift (e.g., framebuffer update handlers,
 *       authentication prompts, clipboard bridging).
 */

#endif /* LIBVNC_AVAILABLE */

#endif /* EVERYTERM_LIBVNC_BRIDGE_H */
