//
//  NodeContext.m
//  NodeLight
//

#import "NodeContext.h"

#import "NodeBuffer.h"
#import "NodeFS.h"
#import "NodeWritableStream.h"
#import "JSObjectUtils.h"
#import "JSStringUtils.h"
#import "JSValueUtils.h"

void NodeContextDelay(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[]) {
    JSValueRef      callback   = arguments[0];
    JSValueCapture* capture    = [JSValueCapture capture:callback context:ctx];
    NodeContext*    context    = JSContextGetNodeContext(ctx);
    JSValueRef*     copy       = malloc(sizeof(JSValueRef) * argumentCount);

    memcpy(copy, arguments, sizeof(JSValueRef) * (argumentCount - 1));
    for (size_t index = 0; index < argumentCount; index++) {
        JSValueProtect(ctx, arguments[index]);
    }
    
    [context nextTick:^{
        JSValueRef exceptionRef = NULL;
        
        JSObjectCallAsFunction(ctx, (JSObjectRef)callback, NULL, argumentCount - 1, copy + 1, &exceptionRef);
        if (exceptionRef) {
            [context unhandledException:exceptionRef inContext:ctx];
        }

        for (size_t index = 0; index < argumentCount; index++) {
            JSValueUnprotect(ctx, copy[index]);
        }
        
        [capture done];
    }];
}

static JSValueRef NodeContextNextTick(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount < 1) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    NodeContextDelay(ctx, argumentCount, arguments);
    return JSValueMakeUndefined(ctx);
}

static JSValueRef NodeContextCwd(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    NodeContext* context = JSContextGetNodeContext(ctx);
    return JSValueFromNSString(ctx, context.fs.cwd);
}

static JSValueRef NodeContextExit(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    int exitCode = 0;
    
    if (argumentCount >= 1) {
        exitCode = (int)JSValueToNumber(ctx, arguments[0], exception);
        if (exception)
            return JSValueMakeUndefined(ctx);
    }
    
    NodeContext* context = JSContextGetNodeContext(ctx);
    [context exit:exitCode];
    return JSValueMakeUndefined(ctx);
}

@implementation NodeContext

- (instancetype)initWithContext:(JSContextRef)context {
    if (self = [super init]) {
        _queue = dispatch_queue_create("org.wd.nodelight.main-queue", DISPATCH_QUEUE_SERIAL);
        _group = dispatch_group_create();
        _fs = [[StandardNodeFS alloc] init];
        
        NSBundle* nodeLightBundle = [NSBundle bundleForClass:[NodeContext class]];
        
        [self loadGlobal:[nodeLightBundle URLForResource:@"BaseSystem" withExtension:@"js"] inContext:context];
        [self loadNativeGlobals:context];
        
        [self loadModule:[nodeLightBundle URLForResource:@"ModulePath" withExtension:@"js"] withName:@"path" inContext:context];
    }
    
    return self;
}

- (void)loadGlobal:(NSURL*)url inContext:(JSContextRef)context {
    @autoreleasepool {
        JSStringRef scriptRef = JSStringCreateWithCFString((__bridge CFStringRef)[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]);
        JSStringRef urlRef    = JSStringCreateWithCFString((__bridge CFStringRef)[url absoluteString]);
        JSValueRef  exception = NULL;
    
        JSEvaluateScript(context, scriptRef, NULL, urlRef, 1, &exception);
        if (exception)
            [self unhandledException:exception inContext:context];
    
        JSStringRelease(scriptRef);
        JSStringRelease(urlRef);
    }
}

- (void)loadNativeGlobals:(JSContextRef)context {
    JSValueRef exception = NULL;
    
    NodeBufferExpose(context, &exception);
    if (exception) {
        [self unhandledException:exception inContext:context];
        exception = NULL;
    }
    
    NodeFSExpose(context, &exception);
    if (exception) {
        [self unhandledException:exception inContext:context];
        exception = NULL;
    }
    
    JSObjectRef process = JSObjectGetProcess(context);
    JSStringRef name = JSStringCreateWithUTF8CString("stdout");
    JSObjectSetProperty(context, process, name, WritableStreamCreate(context, 1), kJSPropertyAttributeNone, NULL);
    JSStringRelease(name);

    name = JSStringCreateWithUTF8CString("stderr");
    JSObjectSetProperty(context, process, name, WritableStreamCreate(context, 2), kJSPropertyAttributeNone, NULL);
    JSStringRelease(name);

    name = JSStringCreateWithUTF8CString("nextTick");
    JSObjectSetProperty(context, process, name, JSObjectMakeFunctionWithCallback(context, name, NodeContextNextTick), kJSPropertyAttributeNone, NULL);
    JSStringRelease(name);

    name = JSStringCreateWithUTF8CString("cwd");
    JSObjectSetProperty(context, process, name, JSObjectMakeFunctionWithCallback(context, name, NodeContextCwd), kJSPropertyAttributeNone, NULL);
    JSStringRelease(name);

    name = JSStringCreateWithUTF8CString("exit");
    JSObjectSetProperty(context, process, name, JSObjectMakeFunctionWithCallback(context, name, NodeContextExit), kJSPropertyAttributeNone, NULL);
    JSStringRelease(name);
}

- (void)loadModule:(NSURL*)url withName:(NSString*)name inContext:(JSContextRef)context {
    @autoreleasepool {
        NSString* script = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        script = [NSString stringWithFormat:@"registerModule(\"%@\",function(module) {%@});", name, script];
        
        JSStringRef scriptRef = JSStringCreateWithCFString((__bridge CFStringRef)script);
        JSStringRef urlRef    = JSStringCreateWithCFString((__bridge CFStringRef)[url absoluteString]);
        JSValueRef  exception = NULL;
        
        JSEvaluateScript(context, scriptRef, NULL, urlRef, 1, &exception);
        if (exception)
            [self unhandledException:exception inContext:context];
        
        JSStringRelease(scriptRef);
        JSStringRelease(urlRef);
    }
}

- (void)writeData:(dispatch_data_t)data inFileDescriptor:(dispatch_fd_t)fd completionBlock:(void (^)(dispatch_data_t data, int error))handler {
    dispatch_group_enter(_group);
    dispatch_write(fd, data, _queue, ^(dispatch_data_t data, int error) {
        @try {
            handler(data, error);
        }
        @finally {
            dispatch_group_leave(_group);
        }
    });
}

- (void)nextTick:(dispatch_block_t)block {
    dispatch_group_async(_group, _queue, block);
}

- (void)mainLoop:(void (^)(int errorCode))block {
    dispatch_group_async(_group, _queue, ^{});
    dispatch_group_notify(_group, _queue, ^{
        block(_exitCode);
    });
}

- (void)exit:(int)exitCode {
    _exitCode = exitCode;
}

- (void)unhandledException:(JSValueRef)exception inContext:(JSContextRef)context {
    NSLog(@"Unhandled exception: %@", JSValueToNSString(context, exception));
}

@end
