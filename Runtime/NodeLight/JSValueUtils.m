//
//  JSValueUtils.m
//  NodeLight
//

#import "JSValueUtils.h"

@implementation JSValueCapture {
    JSGlobalContextRef _context;
    JSValueRef         _valueRef;
}

- (instancetype)initWithValue:(JSValueRef)valueRef context:(JSContextRef)context {
    if (self = [super init]) {
        _context   = JSContextGetGlobalContext(context);
        _valueRef = valueRef;
        JSValueProtect(_context, _valueRef);
        JSGlobalContextRetain(_context);
    }
    
    return self;
}

- (void)dealloc {
    JSValueUnprotect(_context, _valueRef);
    JSGlobalContextRelease(_context);
}

+ (instancetype)capture:(JSValueRef)valueRef context:(JSContextRef)context {
    return [[self alloc] initWithValue:valueRef context:context];
}

- (void)done {
}

@end
