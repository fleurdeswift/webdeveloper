//
//  NodeBuffer.m
//  NodeLight
//

#import "NodeBuffer.h"

#import "JSObjectUtils.h"
#import "JSStringUtils.h"

static void NodeBufferFinalize(JSObjectRef object) {
    CFTypeRef priv = (CFTypeRef)JSObjectGetPrivate(object);
    if (priv)
        CFRelease(priv);
}

static JSValueRef NodeBufferGetLength(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    CFDataRef dataRef = (CFMutableDataRef)JSObjectGetPrivate(object);
    return JSValueMakeNumber(ctx, CFDataGetLength(dataRef));
}

static JSValueRef NodeBufferToString(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (!JSValueIsObjectOfClass(ctx, object, NodeBufferClass()))
        return JSValueFromNSString(ctx, @"Buffer {}");
    
    CFDataRef        dataRef  = (CFMutableDataRef)JSObjectGetPrivate(object);
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSUInteger       length   = CFDataGetLength(dataRef);
    NSUInteger       start    = 0;
    NSUInteger       end      = length;
    
    if (argumentCount >= 1) {
        if (JSValueIsString(ctx, arguments[0]))
            encoding = JSValueToNSStringEncoding(ctx, arguments[0]);
        
        if (argumentCount >= 2) {
            if (JSValueIsNumber(ctx, arguments[1]))
                start = MIN(length, (NSUInteger)JSValueToNumber(ctx, arguments[1], NULL));

            if (argumentCount >= 3) {
                if (JSValueIsNumber(ctx, arguments[2]))
                    end = MIN(length, (NSUInteger)JSValueToNumber(ctx, arguments[2], NULL));
            }
        }
    }
    
    NSData *data = (__bridge NSData *)dataRef;
    if (start > 0 || end < length)
        data = [data subdataWithRange:NSMakeRange(start, end - start)];

    return JSValueFromNSString(ctx, [[NSString alloc] initWithData:data encoding:encoding]);
}

static JSValueRef NodeBufferGet(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    if (JSStringIsEqualToUTF8CString(propertyName, "length"))
        return NodeBufferGetLength(ctx, object, propertyName, exception);
    else if (JSStringIsEqualToUTF8CString(propertyName, "toString"))
        return JSObjectMakeFunctionWithCallback(ctx, propertyName, NodeBufferToString);

    NSString*  propertyNameNS = JSStringToNSString(propertyName);
    NSScanner* scanner        = [NSScanner scannerWithString:propertyNameNS];
    unsigned long long byteIndex;
    
    if ([scanner scanUnsignedLongLong:&byteIndex]) {
        CFDataRef dataRef = (CFMutableDataRef)JSObjectGetPrivate(object);
        
        if (byteIndex < CFDataGetLength(dataRef)) {
            const unsigned char* ptr = CFDataGetBytePtr(dataRef);
            return JSValueMakeNumber(ctx, ptr[byteIndex]);
        }
    }
    
    return JSValueMakeUndefined(ctx);
}

JSValueRef NodeBufferConstructAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount == 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSObjectMake(ctx, NULL, NULL);
    }
    
    if (JSValueIsString(ctx, arguments[0])) {
        NSStringEncoding encoding = NSUTF8StringEncoding;
        
        if (argumentCount > 1) {
            encoding = JSValueToNSStringEncoding(ctx, arguments[1]);
        }
        
        NSMutableData* data = [[JSValueToNSString(ctx, arguments[0]) dataUsingEncoding:encoding] mutableCopy];
        
        CFRetain((__bridge CFTypeRef)data);
        JSObjectSetPrivate(thisObject, (__bridge void*)data);
        return thisObject;
    }
    
    *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
    return JSObjectMake(ctx, NULL, NULL);
}

JSObjectRef NodeBufferConstruct(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    JSObjectRef obj = JSObjectMake(ctx, NodeBufferClass(), NULL);
    
    NodeBufferConstructAsFunction(ctx, constructor, obj, argumentCount, arguments, exception);
    return obj;
}

JSClassRef NodeBufferClass() {
    static JSClassRef classRef;
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        JSStaticValue staticValues[] = {
            { "length", NodeBufferGetLength, NULL, kJSPropertyAttributeDontDelete },
            { NULL, NULL, kJSPropertyAttributeNone },
        };
        
        JSStaticFunction staticFunctions[] = {
            { "toString", NodeBufferToString, kJSPropertyAttributeDontDelete },
            { NULL, NULL, kJSPropertyAttributeNone },
        };
        
        JSClassDefinition def = {
            0, // version,
            kJSClassAttributeNone, // attributes
            "Buffer", // className
            NULL, // parentClass
            staticValues, // staticValues
            staticFunctions, // staticFunctions
            NULL, // initialize
            NodeBufferFinalize, // finalize
            NULL, // hasProperty
            NodeBufferGet, // getProperty
            NULL, // setProperty
            NULL, // deleteProperty
            NULL, // getPropertyNames
            NodeBufferConstructAsFunction, // callAsFunction
            NodeBufferConstruct, // callAsConstructor
            NULL, // hasInstance
            NULL, // convertToType
        };
        
        classRef = JSClassCreate(&def);
    });
    
    return classRef;
}

JSValueRef JSValueFromNSData(JSContextRef context, NSData* data) {
    NSMutableData *dataCopy = [data mutableCopy];
    
    CFRetain((__bridge CFMutableDataRef)dataCopy);
    return JSObjectMake(context, NodeBufferClass(), (__bridge CFMutableDataRef)dataCopy);
}

void NodeBufferExpose(JSContextRef context, JSValueRef* exception) {
    JSObjectRef bufferModuleRef = JSObjectGetModule(context, "buffer", exception);
    if (*exception)
        return;
    
    JSStringRef bufferNameRef = JSStringCreateWithUTF8CString("Buffer");
    JSObjectRef bufferRef = JSObjectMakeConstructor(context, NodeBufferClass(), NodeBufferConstruct);
    JSObjectSetProperty(context, bufferModuleRef, bufferNameRef, bufferRef, kJSPropertyAttributeNone, exception);
    JSObjectSetProperty(context, JSContextGetGlobalObject(context), bufferNameRef, bufferRef, kJSPropertyAttributeNone, exception);
    JSStringRelease(bufferNameRef);

    bufferNameRef = JSStringCreateWithUTF8CString("SlowBuffer");
    JSObjectSetProperty(context, bufferModuleRef, bufferNameRef, bufferRef, kJSPropertyAttributeNone, exception);
    JSStringRelease(bufferNameRef);
}
