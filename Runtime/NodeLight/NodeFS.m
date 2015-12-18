//
//  NodeFS.m
//  NodeLight
//

#import "NodeFS.h"

#import "NodeBuffer.h"
#import "NodeContext.h"
#import "NodeFD.h"
#import "NodeFSStats.h"
#import "JSContextUtils.h"
#import "JSObjectUtils.h"
#import "JSStringUtils.h"
#import "JSValueUtils.h"

#import <sys/stat.h>

@implementation StandardNodeFS {
    NSURL *_cwdURL;
}

- (instancetype)init {
    if (self = [super init]) {
        _cwd    = [[NSFileManager defaultManager] currentDirectoryPath];
        _cwdURL = [NSURL fileURLWithPath:_cwd];
    }
    
    return self;
}

- (void)setCwd:(NSString*)cwd {
    _cwd    = cwd;
    _cwdURL = [NSURL fileURLWithPath:cwd];
}

- (NSString*)map:(NSString*)path {
    return [NSURL fileURLWithPath:path relativeToURL:_cwdURL].path;
}

- (BOOL)exists:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self map:path]];
}

- (NSData *)readFile:(NSString *)path options:(NSDictionary *)options {
    return [NSData dataWithContentsOfFile:[self map:path]];
}

- (NSArray<NSString*>*)readDir:(NSString *)path
{
    NSError *error = nil;
    NSArray <NSString *>* content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self map:path] error:&error];
    if (error)
        @throw error;
    
    return content;
}

- (void)stat:(NSString *)path completionBlock:(void (^)(struct stat s, NSError* error))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        struct stat s;
        
        memset(&s, 0, sizeof(s));
        if (stat([[self map:path] fileSystemRepresentation], &s))
            block(s, [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ @"path": path }]);
        else
            block(s, nil);
    });
}

- (void)stat:(NSString *)path stat:(struct stat*)s error:(NSError**)error
{
    memset(s, 0, sizeof(*s));
    if (stat([[self map:path] fileSystemRepresentation], s)) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ @"path": path }];
    }
}

- (void)close:(dispatch_fd_t)fd {
    close(fd);
}

- (dispatch_fd_t)open:(NSString *)path flags:(NSString *)flags mode:(mode_t)mode error:(NSError**)error
{
    dispatch_fd_t fd = -1;
    
    path = [self map:path];
    
    if ([flags isEqualToString:@"r"] || [flags isEqualToString:@"rs"]) {
        fd = open([path fileSystemRepresentation], O_RDONLY, mode);
    }
    else if ([flags isEqualToString:@"r+"] || [flags isEqualToString:@"rs+"]) {
        fd = open([path fileSystemRepresentation], O_RDWR, mode);
    }
    else if ([flags isEqualToString:@"w"]) {
        fd = open([path fileSystemRepresentation], O_WRONLY | O_CREAT | O_TRUNC, mode);
    }
    else if ([flags isEqualToString:@"wx"]) {
        fd = open([path fileSystemRepresentation], O_WRONLY | O_CREAT | O_TRUNC | O_EXCL, mode);
    }
    else if ([flags isEqualToString:@"w+"]) {
        fd = open([path fileSystemRepresentation], O_RDWR | O_CREAT | O_TRUNC, mode);
    }
    else if ([flags isEqualToString:@"wx+"]) {
        fd = open([path fileSystemRepresentation], O_RDWR | O_CREAT | O_TRUNC | O_EXCL, mode);
    }
    else if ([flags isEqualToString:@"a"]) {
        fd = open([path fileSystemRepresentation], O_WRONLY | O_APPEND | O_CREAT | O_TRUNC, mode);
    }
    else if ([flags isEqualToString:@"ax"]) {
        fd = open([path fileSystemRepresentation], O_WRONLY | O_APPEND | O_CREAT | O_TRUNC | O_EXCL, mode);
    }
    else if ([flags isEqualToString:@"a+"]) {
        fd = open([path fileSystemRepresentation], O_RDWR | O_APPEND | O_CREAT | O_TRUNC, mode);
    }
    else if ([flags isEqualToString:@"ax+"]) {
        fd = open([path fileSystemRepresentation], O_RDWR | O_APPEND | O_CREAT | O_TRUNC | O_EXCL, mode);
    }
    else {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{ @"path": path }];
    }
    
    if (fd < 0) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{ @"path": path }];
    }
    
    return fd;
}

- (NSUInteger)seek:(dispatch_fd_t)fd position:(NSInteger)position error:(NSError**)error {
    off_t pos = lseek(fd, position, SEEK_SET);
    
    if (pos == (off_t)-1) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
    }
    
    return pos;
}

- (NSInteger)write:(dispatch_fd_t)fd data:(NSData*)data error:(NSError**)error {
    ssize_t size = write(fd, data.bytes, data.length);
    
    if (size < 0) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
    }
    
    return size;
}

@end

static JSValueRef NodeFSExistsSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount == 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    NodeContext* context = JSContextGetNodeContext(ctx);
    return JSValueMakeBoolean(ctx, [context.fs exists:JSValueToNSString(ctx, arguments[0])]);
}

static JSValueRef NodeFSReadFileSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount == 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    NSString* path = JSValueToNSString(ctx, arguments[0]);
    NSDictionary* options;
    
    if (argumentCount > 1) {
        options = JSValueToNSDictionary(ctx, arguments[1]);
    }
    
    NodeContext* context = JSContextGetNodeContext(ctx);
    NSData*      data    = [context.fs readFile:path options:options];
    
    if (options[@"encoding"]) {
        NSStringEncoding encoding = NSStringToNSStringEncoding(options[@"encoding"]);
        return JSValueFromNSString(ctx, [[NSString alloc] initWithData:data encoding:encoding]);
    }
    
    return JSValueFromNSData(ctx, data);
}

static JSValueRef NodeFSReadDirSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount == 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    NSString*           path     = JSValueToNSString(ctx, arguments[0]);
    NodeContext*        context  = JSContextGetNodeContext(ctx);
    NSArray<NSString*>* entries  = [context.fs readDir:path];
    JSObjectRef         array    = JSObjectMakeArray(ctx, 0, NULL, NULL);
    
    unsigned int index = 0;
    for (NSString* entry in entries) {
        JSObjectSetPropertyAtIndex(ctx, array, index++, JSValueFromNSString(ctx, entry), NULL);
    }
    
    return array;
}

static JSValueRef NodeFSStat(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount < 2) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    NSString*       path     = JSValueToNSString(ctx, arguments[0]);
    JSObjectRef     callback = (JSObjectRef)arguments[1];
    NodeContext*    context  = JSContextGetNodeContext(ctx);
    JSValueCapture* capture  = [JSValueCapture capture:callback context:ctx];
    
    [context.fs stat:path completionBlock:^(struct stat s, NSError* error) {
        [context nextTick:^{
            JSValueRef args[2];
        
            args[0] = JSValueMakeUndefined(ctx);
            args[1] = args[0];
        
            if (error)
                args[0] = JSObjectMakeErrorFromPOSIXError(ctx, (int)error.code);
            else
                args[1] = NodeFSStatsCreate(ctx, &s);
        
            JSValueRef exceptionRef =  NULL;
            JSObjectCallAsFunction(ctx, callback, NULL, 2, args, &exceptionRef);
            if (exceptionRef) {
                [context unhandledException:exceptionRef inContext:ctx];
            }
            
            [capture done];
        }];
    }];
    
    return JSValueMakeUndefined(ctx);
}

static JSValueRef NodeFSStatSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount == 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    NSString*    path     = JSValueToNSString(ctx, arguments[0]);
    NodeContext* context  = JSContextGetNodeContext(ctx);
    NSError*     error;
    struct stat  s;
    
    [context.fs stat:path stat:&s error:&error];
    if (error) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, (int)error.code);
        return JSValueMakeUndefined(ctx);
    }
    
    return NodeFSStatsCreate(ctx, &s);
}

static JSValueRef NodeFSOpenSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount <= 2) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    mode_t mode = 0666;
    if (argumentCount >= 3) {
        mode = (mode_t)JSValueToNumber(ctx, arguments[2], NULL);;
    }
    
    NSString* path  = JSValueToNSString(ctx, arguments[0]);
    NSString* flags = JSValueToNSString(ctx, arguments[1]);
    
    NodeContext*  context = JSContextGetNodeContext(ctx);
    NSError*      error   = nil;
    dispatch_fd_t fd      = [context.fs open:path flags:flags mode:mode error:&error];

    if (error) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, (int)error.code);
        return JSValueMakeUndefined(ctx);
    }
    
    if (fd < 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EBADF);
        return JSValueMakeUndefined(ctx);
    }
    
    return NodeFDCreate(ctx, fd);
}

static JSValueRef NodeFSCloseSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount == 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    if (!JSValueIsObjectOfClass(ctx, arguments[0], NodeFDClass())) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }
    
    dispatch_fd_t fd = (dispatch_fd_t)(NSInteger)JSObjectGetPrivate((JSObjectRef)arguments[0]);
    if (fd <= 0) {
        return JSValueMakeUndefined(ctx);
    }
    
    NodeContext* context = JSContextGetNodeContext(ctx);
    [context.fs close:fd];
    JSObjectSetPrivate((JSObjectRef)arguments[0], (void*)(NSInteger)-1);
    return JSValueMakeUndefined(ctx);
}

static JSValueRef NodeFSWriteSync(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    if (argumentCount < 2) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EINVAL);
        return JSValueMakeUndefined(ctx);
    }

    dispatch_fd_t fd = (dispatch_fd_t)(NSInteger)JSObjectGetPrivate((JSObjectRef)arguments[0]);
    if (fd <= 0) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EBADF);
        return JSValueMakeUndefined(ctx);
    }

    JSValueRef offset   = JSValueMakeUndefined(ctx);
    JSValueRef length   = offset;
    JSValueRef position = offset;
    JSValueRef encoding = offset;
    
    if (JSValueIsObjectOfClass(ctx, arguments[1], NodeBufferClass())) {
        if (argumentCount >= 5) {
            offset   = arguments[2];
            length   = arguments[3];
            position = arguments[4];
        }
        else if (argumentCount >= 4) {
            offset = arguments[2];
            length = arguments[3];
        }
        else if (argumentCount >= 3) {
            offset = arguments[2];
        }
    }
    else {
        if (argumentCount >= 4) {
            position = arguments[2];
            encoding = arguments[3];
        }
        else if (argumentCount >= 3) {
            if (JSValueIsString(ctx, arguments[2]))
                encoding = arguments[2];
            else
                position = arguments[2];
        }
    }
    
    NSData* data = JSValueToNSData(ctx, arguments[1], encoding);
    
    if (JSValueIsNumber(ctx, offset) && JSValueIsNumber(ctx, length)) {
        data = [data subdataWithRange:NSMakeRange(
                    (NSInteger)JSValueToNumber(ctx, offset, NULL),
                    (NSInteger)JSValueToNumber(ctx, length, NULL))];
    }
    
    NodeContext* context = JSContextGetNodeContext(ctx);
    NSError*     error   = nil;

    if (JSValueIsNumber(ctx, position)) {
        [context.fs seek:fd position:(NSInteger)JSValueToNumber(ctx, position, NULL) error:&error];
        if (error) {
            *exception = JSObjectMakeErrorFromPOSIXError(ctx, EBADF);
            return JSValueMakeUndefined(ctx);
        }
    }

    NSInteger written = [context.fs write:fd data:data error:&error];
    if (error) {
        *exception = JSObjectMakeErrorFromPOSIXError(ctx, EBADF);
        return JSValueMakeUndefined(ctx);
    }
    
    return JSValueMakeNumber(ctx, written);
}

void NodeFSExpose(JSContextRef context, JSValueRef* exception) {
    JSObjectRef fsModuleRef = JSObjectGetModule(context, "fs", exception);
    if (*exception)
        return;
    
    JSStringRef nameRef = JSStringCreateWithUTF8CString("existsSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSExistsSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);

    nameRef = JSStringCreateWithUTF8CString("readFileSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSReadFileSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);

    nameRef = JSStringCreateWithUTF8CString("readdirSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSReadDirSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);

    nameRef = JSStringCreateWithUTF8CString("statSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSStatSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);

    nameRef = JSStringCreateWithUTF8CString("stat");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSStat), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);

    nameRef = JSStringCreateWithUTF8CString("openSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSOpenSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);
    
    nameRef = JSStringCreateWithUTF8CString("closeSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSCloseSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);

    nameRef = JSStringCreateWithUTF8CString("writeSync");
    JSObjectSetProperty(context, fsModuleRef, nameRef, JSObjectMakeFunctionWithCallback(context, nameRef, NodeFSWriteSync), kJSPropertyAttributeNone, exception);
    JSStringRelease(nameRef);
}
