//
//  NodeFSStats.m
//  NodeLight
//

#import "NodeFSStats.h"

#import "JSObjectUtils.h"

#import <sys/stat.h>

static JSValueRef NodeBufferIsMode(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception, int mode) {
    JSStringRef modeName = JSStringCreateWithUTF8CString("mode");
    JSValueRef modeRef = JSObjectGetProperty(ctx, object, modeName, exception);
    JSStringRelease(modeName);
    if (exception)
        return modeRef;
    
    double modeDouble = JSValueToNumber(ctx, modeRef, exception);
    if (exception)
        return modeRef;
    
    return JSValueMakeBoolean(ctx, ((((int)modeDouble) & mode) == mode)? 1: 0);
}

static JSValueRef NodeBufferIsFile(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFREG);
}

static JSValueRef NodeBufferIsDirectory(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFDIR);
}

static JSValueRef NodeBufferIsBlockDevice(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFBLK);
}

static JSValueRef NodeBufferIsCharacterDevice(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFCHR);
}

static JSValueRef NodeBufferIsSymbolicLink(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFLNK);
}

static JSValueRef NodeBufferIsFIFO(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFIFO);
}

static JSValueRef NodeBufferIsSocket(JSContextRef ctx, JSObjectRef function, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return NodeBufferIsMode(ctx, function, object, argumentCount, arguments, exception, S_IFSOCK);
}

static JSClassRef NodeFSStatsClass() {
    static JSClassRef classRef;
    static dispatch_once_t token = 0;
    
    dispatch_once(&token, ^{
        JSStaticValue staticValues[] = {
            { NULL, NULL, kJSPropertyAttributeNone },
        };
        
        JSStaticFunction staticFunctions[] = {
            { "isFile",            NodeBufferIsFile,            kJSPropertyAttributeDontDelete },
            { "isDirectory",       NodeBufferIsDirectory,       kJSPropertyAttributeDontDelete },
            { "isBlockDevice",     NodeBufferIsBlockDevice,     kJSPropertyAttributeDontDelete },
            { "isCharacterDevice", NodeBufferIsCharacterDevice, kJSPropertyAttributeDontDelete },
            { "isSymbolicLink",    NodeBufferIsSymbolicLink,    kJSPropertyAttributeDontDelete },
            { "isFIFO",            NodeBufferIsFIFO,            kJSPropertyAttributeDontDelete },
            { "isSocket",          NodeBufferIsSocket,          kJSPropertyAttributeDontDelete },
            { NULL,                NULL,                        kJSPropertyAttributeNone },
        };
        
        JSClassDefinition def = {
            0, // version,
            kJSClassAttributeNone, // attributes
            "NodeFSStats", // className
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

JSObjectRef NodeFSStatsCreate(JSContextRef context, const struct stat* stat) {
    JSObjectRef obj = JSObjectMake(context, NodeFSStatsClass(), NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "dev",       JSValueMakeNumber(context, stat->st_dev),                   kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "ino",       JSValueMakeNumber(context, stat->st_ino),                   kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "mode",      JSValueMakeNumber(context, stat->st_mode),                  kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "nlink",     JSValueMakeNumber(context, stat->st_nlink),                 kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "uid",       JSValueMakeNumber(context, stat->st_uid),                   kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "gid",       JSValueMakeNumber(context, stat->st_gid),                   kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "rdev",      JSValueMakeNumber(context, stat->st_rdev),                  kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "size",      JSValueMakeNumber(context, stat->st_size),                  kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "blksize",   JSValueMakeNumber(context, stat->st_blksize),               kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "blocks",    JSValueMakeNumber(context, stat->st_blocks),                kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "atime",     JSObjectMakeDateFromPOSIXTime(context, stat->st_atime),     kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "mtime",     JSObjectMakeDateFromPOSIXTime(context, stat->st_mtime),     kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "ctime",     JSObjectMakeDateFromPOSIXTime(context, stat->st_ctime),     kJSPropertyAttributeNone, NULL);
    JSObjectSetPropertyWithUTF8StringName(context, obj, "birthtime", JSObjectMakeDateFromPOSIXTime(context, stat->st_birthtime), kJSPropertyAttributeNone, NULL);
    return obj;
}
