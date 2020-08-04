#import "FlutterContactPlugin.h"
#import <flutter_contact/flutter_contact-Swift.h>

@implementation FlutterContactPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if (@available(iOS 9.0, *)) {
        [SwiftFlutterContactPlugin registerWithRegistrar:registrar];
    } else {
        // Fallback on earlier versions
    }
}
@end
