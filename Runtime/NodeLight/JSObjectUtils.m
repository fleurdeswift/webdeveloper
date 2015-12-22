//
//  JSObjectUtils.m
//  NodeLight
//

#import "JSContextUtils.h"
#import "JSObjectUtils.h"
#import "JSStringUtils.h"

#import "NodeContext.h"

JSValueRef JSObjectCallAsFunctionAndLogException(JSContextRef context, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[]) {
    JSValueRef exception   = NULL;
    JSValueRef returnValue = NULL;
   
    returnValue = JSObjectCallAsFunction(context, object, thisObject, argumentCount, arguments, &exception);
    
    if (exception) {
        [JSContextGetNodeContext(context) unhandledException:exception inContext:context];
    }
    
    return returnValue;
}

JSValueRef JSObjectCallAsFunctionAndThrowException(JSContextRef context, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[]) {
    JSValueRef exception   = NULL;
    JSValueRef returnValue = NULL;
    
    returnValue = JSObjectCallAsFunction(context, object, thisObject, argumentCount, arguments, &exception);
    if (exception)
        @throw [NSException exceptionWithName:@"JavaScript Exception" reason:JSValueToNSString(context, exception) userInfo:nil];
    
    return returnValue;
}

JSValueRef JSObjectMakeErrorFromPOSIXError(JSContextRef context, int err) {
    if (err == 0)
        return JSValueMakeUndefined(context);
    
    JSValueRef errorMessage = JSValueFromNSString(context, [NSString stringWithUTF8String:strerror(err)]);
    return JSObjectMakeError(context, 1, &errorMessage, NULL);
}

void JSObjectSetPropertyWithUTF8StringName(JSContextRef ctx, JSObjectRef object, const char* propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception) {
    JSStringRef propertyNameRef = JSStringCreateWithUTF8CString(propertyName);
    JSObjectSetProperty(ctx, object, propertyNameRef, value, attributes, exception);
    JSStringRelease(propertyNameRef);
}

JSObjectRef JSObjectMakeDateFromPOSIXTime(JSContextRef context, time_t time) {
    JSValueRef timeRef = JSValueMakeNumber(context, time);
    return JSObjectMakeDate(context, 1, &timeRef, NULL);
}

JSObjectRef JSObjectGetModule(JSContextRef context, const char* module, JSValueRef* exception) {
    JSObjectRef globalObject    = JSContextGetGlobalObject(context);
    JSStringRef requireNameRef  = JSStringCreateWithUTF8CString("require");
    JSValueRef  requireValueRef = JSObjectGetProperty(context, globalObject, requireNameRef, exception);
    
    JSStringRelease(requireNameRef);
    if (*exception)
        return NULL;
    
    JSStringRef moduleNameRef = JSStringCreateWithUTF8CString(module);
    JSValueRef moduleNameValueRef = JSValueMakeString(context, moduleNameRef);
    JSValueRef moduleRef = JSObjectCallAsFunction(context, (JSObjectRef)requireValueRef, NULL, 1, &moduleNameValueRef, exception);
    
    JSStringRelease(moduleNameRef);
    if (*exception)
        return NULL;
    
    return (JSObjectRef)moduleRef;
}

JSObjectRef JSObjectGetProcess(JSContextRef context) {
    JSObjectRef globalObject    = JSContextGetGlobalObject(context);
    JSStringRef processNameRef  = JSStringCreateWithUTF8CString("process");
    JSValueRef  processValueRef = JSObjectGetProperty(context, globalObject, processNameRef, NULL);
    
    JSStringRelease(processNameRef);
    return (JSObjectRef)processValueRef;
}

JSValueRef JSExecuteInSandbox(JSContextRef context, NSString* filename, NSString* code, NSString* codeURL, JSValueRef* exception) {
    JSObjectRef globalObject          = JSContextGetGlobalObject(context);
    JSStringRef createSandboxNameRef  = JSStringCreateWithUTF8CString("createSandbox");
    JSValueRef  createSandboxValueRef = JSObjectGetProperty(context, globalObject, createSandboxNameRef, exception);
    
    JSStringRelease(createSandboxNameRef);
    if (*exception)
        return NULL;
    
    JSValueRef fileNameRef = JSValueFromNSString(context, filename);
    JSObjectRef sandboxRef = JSObjectCallAsConstructor(context, (JSObjectRef)createSandboxValueRef, 1, &fileNameRef, exception);
    if (*exception)
        return NULL;

    code = [NSString stringWithFormat:@"(function() { var __filename = \"%@\"; %@})();", filename, code];
    
    JSStringRef codeRef    = JSStringCreateWithCFString((__bridge CFStringRef)code);
    JSStringRef codeURLRef = JSStringCreateWithCFString((__bridge CFStringRef)codeURL);
    JSValueRef  returnRef  = JSEvaluateScript(context, codeRef, sandboxRef, codeURLRef, 1, exception);
    
    JSStringRelease(codeRef);
    JSStringRelease(codeURLRef);
    if (*exception)
        return NULL;
    
    return returnRef;
}
