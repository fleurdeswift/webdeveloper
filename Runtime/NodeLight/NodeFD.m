//
//  NodeFD.m
//  NodeLight
//

#import "NodeFD.h"

static void NodeFDFinalize(JSObjectRef object) {
    dispatch_fd_t fd = (dispatch_fd_t)(NSInteger)JSObjectGetPrivate(object);
    
    if (fd >= 0) {
        close(fd);
    }
}

static JSValueRef NodeFDConvertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception) {
    switch (type) {
        case kJSTypeString: {
            char fds[64];
            sprintf(fds, "%li", (long)JSObjectGetPrivate(object));
            JSStringRef str = JSStringCreateWithUTF8CString(fds);
            JSValueRef  val = JSValueMakeString(ctx, str);
            JSStringRelease(str);
            return val;
        }
        case kJSTypeObject:  return object;
        case kJSTypeNumber:  return JSValueMakeNumber(ctx, (NSInteger)JSObjectGetPrivate(object));
        case kJSTypeBoolean: return JSValueMakeBoolean(ctx, JSObjectGetPrivate(object) != NULL);
        case kJSTypeNull:    return JSValueMakeNull(ctx);
        default:             return JSValueMakeUndefined(ctx);
    }
}

JSClassRef NodeFDClass() {
    static JSClassRef classRef;
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        JSClassDefinition def = {
            0, // version,
            kJSClassAttributeNone, // attributes
            "NodeFD", // className
            NULL, // parentClass
            NULL, // staticValues
            NULL, // staticFunctions
            NULL, // initialize
            NodeFDFinalize, // finalize
            NULL, // hasProperty
            NULL, // getProperty
            NULL, // setProperty
            NULL, // deleteProperty
            NULL, // getPropertyNames
            NULL, // callAsFunction
            NULL, // callAsConstructor
            NULL, // hasInstance
            NodeFDConvertToType, // convertToType
        };
        
        classRef = JSClassCreate(&def);
    });
    
    return classRef;
}

JSObjectRef NodeFDCreate(JSContextRef context, dispatch_fd_t fd) {
    return JSObjectMake(context, NodeFDClass(), (void*)(NSInteger)fd);
}
