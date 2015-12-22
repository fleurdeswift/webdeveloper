//
//  NodeContext.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

@protocol NodeFS;

@interface NodeContext : NSObject
@property (nonatomic, retain, readonly) dispatch_queue_t queue;
@property (nonatomic, retain, readonly) dispatch_group_t group;
@property (nonatomic, assign) int exitCode;
@property (nonatomic, retain) id <NodeFS> fs;

- (void)setArguments:(NSArray <NSString*>*)argv inContext:(JSContextRef)context;

- (instancetype)initWithContext:(JSContextRef)context;

- (void)mainLoop:(void (^)(int errorCode))block;
- (void)nextTick:(dispatch_block_t)block;
- (void)exit:(int)exitCode;

- (void)writeData:(dispatch_data_t)data inFileDescriptor:(dispatch_fd_t)fd completionBlock:(void (^)(dispatch_data_t data, int error))handler;

- (void)unhandledException:(JSValueRef)exception inContext:(JSContextRef)context;

- (void)loadModule:(const char*)code withName:(NSString*)name withPath:(NSString*)path inContext:(JSContextRef)context;
- (void)loadModule:(NSURL*)url withName:(NSString*)name inContext:(JSContextRef)context;
@end

NodeContext* JSContextGetNodeContext(JSContextRef context);
void NodeContextDelay(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[]);
