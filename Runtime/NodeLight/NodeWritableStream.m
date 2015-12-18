//
//  NodeWritableStream.m
//  NodeLight
//

#import "NodeWritableStream.h"

#import "JSContextUtils.h"
#import "JSObjectUtils.h"
#import "JSStringUtils.h"
#import "JSValueUtils.h"
#import "NSDataExtensions.h"

#import "NodeContext.h"

static JSValueRef WritableStreamWrite(JSContextRef context, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    NSData*         data        = JSValueToNSData(context, arguments[0], argumentCount > 1? arguments[1]: NULL);
    NodeContext*    nodeContext = JSContextGetNodeContext(context);
    dispatch_fd_t   fd          = (int)(NSInteger)JSObjectGetPrivate(thisObject);
    JSObjectRef     callback    = argumentCount > 2? (JSObjectRef)arguments[2]: NULL;
    JSValueCapture* callbackCapture;

    if (JSObjectIsFunction(context, callback))
        callbackCapture = [JSValueCapture capture:callback context:context];
    else
        callback = NULL;
    
    [nodeContext writeData:data.dispatchData inFileDescriptor:fd completionBlock:^(dispatch_data_t data, int error) {
        if (!callback) {
            return;
        }

        [nodeContext nextTick:^{
            JSValueRef errorObject = JSObjectMakeErrorFromPOSIXError(context, error);
            JSObjectCallAsFunctionAndLogException(context, callback, NULL, 1, &errorObject);
            [callbackCapture done];
        }];
    }];
    
    return JSValueMakeBoolean(context, YES);
}

JSClassRef WritableStreamClass() {
    static JSClassRef classRef;
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        JSStaticValue staticValues[] = {
            { NULL, NULL, kJSPropertyAttributeNone },
        };
        
        JSStaticFunction staticFunctions[] = {
            { "write", WritableStreamWrite, kJSPropertyAttributeDontDelete },
            { NULL, NULL, kJSPropertyAttributeNone },
        };
        
        JSClassDefinition def = {
            0, // version,
            kJSClassAttributeNone, // attributes
            "WritableStream", // className
            NULL, // parentClass
            staticValues, // staticValues
            staticFunctions, // staticFunctions
            NULL, // initialize
            NULL, // finalize
            NULL, // hasProperty
            NULL, // getProperty
            NULL, // setProperty
            NULL, // deleteProperty
            NULL, // getPropertyNames
            NULL, // callAsFunction
            NULL, // callAsConstructor
            NULL, // hasInstance
            NULL, // convertToType
        };
        
        classRef = JSClassCreate(&def);
    });
    
    return classRef;
}

JSValueRef WritableStreamCreate(JSContextRef context, dispatch_fd_t fd) {
    return JSObjectMake(context, WritableStreamClass(), (void*)(NSInteger)fd);
}
