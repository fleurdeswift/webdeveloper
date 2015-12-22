//
//  JSObjectUtils.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

JSValueRef JSObjectCallAsFunctionAndLogException(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[]);
JSValueRef JSObjectCallAsFunctionAndThrowException(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[]);
JSValueRef JSObjectMakeErrorFromPOSIXError(JSContextRef context, int err);
void JSObjectSetPropertyWithUTF8StringName(JSContextRef ctx, JSObjectRef object, const char* propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception);
JSObjectRef JSObjectMakeDateFromPOSIXTime(JSContextRef context, time_t time);
JSObjectRef JSObjectGetModule(JSContextRef context, const char* module, JSValueRef* exception);
JSObjectRef JSObjectGetProcess(JSContextRef context);
JSValueRef JSExecuteInSandbox(JSContextRef context, NSString* filename, NSString* code, NSString* codeURL, JSValueRef* exception);
