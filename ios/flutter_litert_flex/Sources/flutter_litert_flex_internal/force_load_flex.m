// This file forces the linker to include the FlexDelegate plugin symbols from
// the TensorFlowLiteFlex static framework. The -ObjC linker flag loads this
// object file (it contains an ObjC class), and the __attribute__((used))
// references force the linker to pull in the plugin symbols from the static
// archive. Without this, those symbols would be stripped since they're only
// looked up at runtime via DynamicLibrary.process().

#import <Foundation/Foundation.h>

extern void *tflite_plugin_create_delegate(const char *const *, const char *const *, size_t, void (*)(const char *));
extern void tflite_plugin_destroy_delegate(void *);

__attribute__((used)) static void *_force_create = (void *)&tflite_plugin_create_delegate;
__attribute__((used)) static void *_force_destroy = (void *)&tflite_plugin_destroy_delegate;

@interface _FlutterLitertFlexForceLoad : NSObject
@end

@implementation _FlutterLitertFlexForceLoad
@end
