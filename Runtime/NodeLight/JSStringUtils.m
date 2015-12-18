//
//  JSStringUtils.m
//  NodeLight
//

#import "JSStringUtils.h"

#import "NodeBuffer.h"

NSString* JSStringToNSString(JSStringRef str) {
    CFStringRef strCF = JSStringCopyCFString(NULL, str);
    NSString*   strNS = (__bridge NSString*)strCF;
    
    CFRelease(strCF);
    return strNS;
}

NSString* JSValueToNSString(JSContextRef context, JSValueRef value) {
    if ((value == nil) || JSValueIsUndefined(context, value) || JSValueIsNull(context, value))
        return nil;
    
    JSValueRef  exception = NULL;
    JSStringRef str       = JSValueToStringCopy(context, value, &exception);
    
    if (!str && exception)
        @throw [NSException exceptionWithName:@"JavaScript Exception" reason:JSValueToNSString(context, exception) userInfo:nil];
    
    @try {
        return JSStringToNSString(str);
    }
    @finally {
        JSStringRelease(str);
    }
}

NSStringEncoding NSStringToNSStringEncoding(NSString* strNS) {
    if (strNS == nil)
        return NSUTF8StringEncoding;
    
    if ([strNS caseInsensitiveCompare:@"utf8"] == NSOrderedSame)
        return NSUTF8StringEncoding;
    else if ([strNS caseInsensitiveCompare:@"ascii"] == NSOrderedSame)
        return NSASCIIStringEncoding;
    else if ([strNS caseInsensitiveCompare:@"utf16le"] == NSOrderedSame)
        return NSUTF16LittleEndianStringEncoding;
    else if ([strNS caseInsensitiveCompare:@"utf16be"] == NSOrderedSame)
        return NSUTF16BigEndianStringEncoding;
    else if ([strNS caseInsensitiveCompare:@"utf16"] == NSOrderedSame)
        return NSUTF16StringEncoding;
    else if ([strNS caseInsensitiveCompare:@"ucs2"] == NSOrderedSame)
        return NSUTF16StringEncoding;
    
    [[NSException exceptionWithName:@"Encoding" reason:[NSString stringWithFormat:@"Invalid encoding: %@", strNS] userInfo:nil] raise];
    return NSUTF8StringEncoding;
}

NSStringEncoding JSStringToNSStringEncoding(JSStringRef str) {
    if (str == NULL)
        return NSUTF8StringEncoding;
    return NSStringToNSStringEncoding(JSStringToNSString(str));
}

NSStringEncoding JSValueToNSStringEncoding(JSContextRef context, JSValueRef str) {
    return NSStringToNSStringEncoding(JSValueToNSString(context, str));
}

JSValueRef JSValueFromNSString(JSContextRef context, NSString* str) {
    if (str == nil)
        return JSValueMakeUndefined(context);
    
    JSStringRef string      = JSStringCreateWithCFString((__bridge CFStringRef)str);
    JSValueRef  stringValue = JSValueMakeString(context, string);
    
    JSStringRelease(string);
    return stringValue;
}

NSData* JSValueToNSData(JSContextRef context, JSValueRef object, JSValueRef encoding) {
    if (JSValueIsObjectOfClass(context, object, NodeBufferClass())) {
        return [((__bridge NSMutableData*)JSObjectGetPrivate((JSObjectRef)object)) copy];
    }
    
    return [JSValueToNSString(context, object) dataUsingEncoding:JSValueToNSStringEncoding(context, encoding)];
}

NSArray* JSValueToNSArray(JSContextRef context, JSValueRef valueRef) {
    if (!JSValueIsArray(context, valueRef))
        return @[];
    
    JSStringRef lengthNameRef = JSStringCreateWithUTF8CString("length");
    JSValueRef  lengthRef     = JSObjectGetProperty(context, (JSObjectRef)valueRef, lengthNameRef, NULL);
    JSStringRelease(lengthNameRef);
    
    unsigned int    length = (unsigned int)JSValueToNumber(context, lengthRef, NULL);
    NSMutableArray* ar     = [[NSMutableArray alloc] initWithCapacity:length];
    
    for (unsigned int index = 0; index < length; index++) {
        JSValueRef exception = NULL;
        JSValueRef val = JSObjectGetPropertyAtIndex(context, (JSObjectRef)valueRef, index, &exception);
        if (exception)
            continue;
       
        id valNS = JSValueToNSObject(context, val);
        if (!valNS)
            continue;
        
        [ar addObject:valNS];
    }
    
    return [ar copy];
}

NSDictionary* JSValueToNSDictionary(JSContextRef context, JSValueRef valueRef) {
    if (!JSValueIsObject(context, valueRef))
        return @{};
    
    JSPropertyNameArrayRef names = JSObjectCopyPropertyNames(context, (JSObjectRef)valueRef);
    size_t                 count = JSPropertyNameArrayGetCount(names);
    NSMutableDictionary*   di    = [[NSMutableDictionary alloc] initWithCapacity:count];

    for (size_t index = 0; index < count; index++) {
        JSStringRef name      = JSPropertyNameArrayGetNameAtIndex(names, index);
        JSValueRef  exception = NULL;
        JSValueRef  value     = JSObjectGetProperty(context, (JSObjectRef)valueRef, name, &exception);
        
        if (exception) {
            JSStringRelease(name);
            continue;
        }
        
        id valNS = JSValueToNSObject(context, value);
        if (!valNS) {
            JSStringRelease(name);
            continue;
        }
    
        di[JSStringToNSString(name)] = valNS;
        JSStringRelease(name);
    }
    
    JSPropertyNameArrayRelease(names);
    return di;
}

id JSValueToNSObject(JSContextRef context, JSValueRef valueRef) {
    if (JSValueIsNumber(context, valueRef)) {
        return @(JSValueToNumber(context, valueRef, NULL));
    }
    else if (JSValueIsString(context, valueRef)) {
        return JSValueToNSString(context, valueRef);
    }
    else if (JSValueIsBoolean(context, valueRef)) {
        return [NSNumber numberWithBool:JSValueToBoolean(context, valueRef)];
    }
    else if (JSValueIsNull(context, valueRef)) {
        return [NSNull null];
    }
    else if (JSValueIsUndefined(context, valueRef)) {
        return nil;
    }
    else if (JSValueIsArray(context, valueRef)) {
        return JSValueToNSArray(context, valueRef);
    }
    else {
        return JSValueToNSDictionary(context, valueRef);
    }
}
