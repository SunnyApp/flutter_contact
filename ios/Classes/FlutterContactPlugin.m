#import "FlutterContactPlugin.h"
#import <flutter_contact/flutter_contact-Swift.h>

@implementation FlutterContactPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterContactPlugin registerWithRegistrar:registrar];
}
@end
