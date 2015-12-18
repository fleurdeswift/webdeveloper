//
//  NodeWritableStream.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

JSValueRef WritableStreamCreate(JSContextRef context, dispatch_fd_t fd);
