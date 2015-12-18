//
//  NSDataExtensions.m
//  NodeLight
//

#import "NSDataExtensions.h"

@implementation NSData (NodeLightExtensions)

- (dispatch_data_t)dispatchData
{
    CFDataRef dataRef = (__bridge CFDataRef)self;
    CFRetain(dataRef);
    return dispatch_data_create(self.bytes, self.length, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        CFRelease(dataRef);
    });
}

@end
