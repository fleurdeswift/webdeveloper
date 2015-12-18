//
//  JSStringUtils.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

NSString* JSStringToNSString(JSStringRef str);
NSString* JSValueToNSString(JSContextRef context, JSValueRef value);

NSStringEncoding JSStringToNSStringEncoding(JSStringRef str);
NSStringEncoding JSValueToNSStringEncoding(JSContextRef context, JSValueRef value);
NSStringEncoding NSStringToNSStringEncoding(NSString* str);

JSValueRef JSValueFromNSString(JSContextRef context, NSString* str);

NSData*       JSValueToNSData      (JSContextRef context, JSValueRef object, JSValueRef encoding);
id            JSValueToNSObject    (JSContextRef context, JSValueRef valueRef);
NSDictionary* JSValueToNSDictionary(JSContextRef context, JSValueRef valueRef);
NSArray*      JSValueToNSArray     (JSContextRef context, JSValueRef valueRef);
