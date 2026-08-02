//
//  MilliVaultBridgePlugin.m
//
//  Objective-C registration for the MilliVaultBridge Capacitor plugin.
//  Capacitor picks this up automatically at build time.
//

#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(MilliVaultBridge, "MilliVaultBridge",
    CAP_PLUGIN_METHOD(update, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(read,   CAPPluginReturnPromise);
)
