//
//  JSValueUtils.h
//  NodeLight
//

#import <JavaScriptCore/JavaScriptCore.h>

@interface JSValueCapture : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValue:(JSValueRef)valueRef context:(JSContextRef)context;
+ (instancetype)capture:(JSValueRef)valueRef context:(JSContextRef)context;
- (void)done;

@end
