//
//  NodeFD.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

JSClassRef NodeFDClass();
JSObjectRef NodeFDCreate(JSContextRef context, dispatch_fd_t fd);
