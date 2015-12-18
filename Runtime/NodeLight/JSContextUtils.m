//
//  JSContextUtils.m
//  NodeLight
//

#import "JSContextUtils.h"
#import "JSStringUtils.h"

#import "NodeContext.h"

static JSStringRef RuntimePropertyName() {
    static JSStringRef     name  = NULL;
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        name = JSStringCreateWithUTF8CString("____NodeContextRuntime____");
    });
    
    return name;
}

static void NodeContextFinalize(JSObjectRef object) {
    CFRelease((CFTypeRef)JSObjectGetPrivate(object));
}

static JSClassRef NodeContextClass() {
    static JSClassRef classRef;
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        JSClassDefinition def = {
            0, // version,
            kJSClassAttributeNone, // attributes
            "NodeLightJSContext", // className
            NULL, // parentClass
            NULL, // staticValues
            NULL, // staticFunctions
            NULL, // initialize
            NodeContextFinalize, // finalize
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

NodeContext* JSContextGetNodeContext(JSContextRef context) {
    JSObjectRef object       = JSContextGetGlobalObject(context);
    JSValueRef  runtimeValue = JSObjectGetProperty(context, object, RuntimePropertyName(), NULL);
    
    if (JSValueIsObjectOfClass(context, runtimeValue, NodeContextClass())) {
        return (__bridge NodeContext*)JSObjectGetPrivate((JSObjectRef)runtimeValue);
    }

    NodeContext* nodeContext = [[NodeContext alloc] initWithContext:context];
    
    CFRetain((__bridge CFTypeRef)nodeContext);
    JSObjectSetProperty(
        context,
        object,
        RuntimePropertyName(),
        JSObjectMake(context, NodeContextClass(), (__bridge void*)nodeContext),
        kJSPropertyAttributeReadOnly | kJSPropertyAttributeDontEnum,
        NULL);

    return nodeContext;
}
