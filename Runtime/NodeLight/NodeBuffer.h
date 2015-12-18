//
//  NodeBuffer.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

JSClassRef NodeBufferClass();
void NodeBufferExpose(JSContextRef context, JSValueRef* exception);
JSValueRef JSValueFromNSData(JSContextRef context, NSData *data);
