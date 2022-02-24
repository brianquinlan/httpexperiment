#import "PlatformhttpPlugin.h"
#if __has_include(<platformhttp/platformhttp-Swift.h>)
#import <platformhttp/platformhttp-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "platformhttp-Swift.h"
#endif

@implementation PlatformhttpPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPlatformhttpPlugin registerWithRegistrar:registrar];
}
@end
