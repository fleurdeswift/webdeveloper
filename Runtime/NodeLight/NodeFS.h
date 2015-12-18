//
//  NodeFS.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

@protocol NodeFS
@property (nonatomic, retain) NSString* cwd;

#pragma mark -
- (NSData *)readFile:(NSString *)path options:(NSDictionary *)options;

#pragma mark -
- (NSArray<NSString*>*)readDir:(NSString *)path;

#pragma mark -
- (BOOL)exists:(NSString *)path;
- (void)stat:(NSString *)path completionBlock:(void (^)(struct stat s, NSError* error))block;
- (void)stat:(NSString *)path stat:(struct stat*)s error:(NSError**)error;

#pragma mark -
- (dispatch_fd_t)open:(NSString *)path flags:(NSString *)flags mode:(mode_t)mode error:(NSError**)error;
- (NSUInteger)seek:(dispatch_fd_t)fd position:(NSInteger)position error:(NSError**)error;
- (NSInteger)write:(dispatch_fd_t)fd data:(NSData*)data error:(NSError**)error;
- (void)close:(dispatch_fd_t)fd;
@end

@interface StandardNodeFS : NSObject <NodeFS>
@property (nonatomic, retain) NSString* cwd;
- (NSString*)map:(NSString*)path;
@end

void NodeFSExpose(JSContextRef context, JSValueRef* exception);
