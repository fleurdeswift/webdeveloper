//
//  main.m
//  tsc
//

#import <JavaScriptCore/JavaScriptCore.h>
#import <NodeLight/NodeLight.h>

extern const unsigned char tsc_js[];
extern const unsigned int  tsc_js_len;
extern const unsigned char lib_d_ts[];
extern const unsigned int  lib_d_ts_len;
extern const unsigned char lib_es6_d_ts[];
extern const unsigned int  lib_es6_d_ts_len;

int main(int argc, const char * argv[]) {
    JSContext*   context     = [[JSContext alloc] init];
    NodeContext* nodeContext = JSContextGetNodeContext(context.JSGlobalContextRef);
    
    @autoreleasepool {
        JSContextRef ctx = context.JSGlobalContextRef;
        
        {
            NSData* libes5d = [NSData dataWithBytesNoCopy:(void*)lib_d_ts     length:lib_d_ts_len     freeWhenDone:NO];
            NSData* libes6d = [NSData dataWithBytesNoCopy:(void*)lib_es6_d_ts length:lib_es6_d_ts_len freeWhenDone:NO];
        
            nodeContext.fs = [[InlineNodeFS alloc] initWithInlineMap:@{
                @"lib.d.ts":                libes5d,
                @"lib.es6.d.ts":            libes6d,
                @"/built-ins/lib.d.ts":     libes5d,
                @"/built-ins/lib.es6.d.ts": libes6d,
            } chain:nodeContext.fs];
        }
        
        {
            NSMutableArray<NSString*>* args = [NSMutableArray array];
            NSString*                  arg0 = [NSString stringWithUTF8String:argv[0]];
            
            [args addObject:arg0];
            [args addObject:arg0];
            
            for (int index = 1; index < argc; index++) {
                [args addObject:[NSString stringWithUTF8String:argv[index]]];
            }
            
            [nodeContext setArguments:args inContext:ctx];
        }
        
        JSValueRef exception = NULL;
        JSExecuteInSandbox(ctx, @"/built-ins/tsc.js", [[NSString alloc] initWithBytesNoCopy:(void*)tsc_js length:tsc_js_len encoding:NSUTF8StringEncoding freeWhenDone:NO], @"tsc.js", &exception);
        if (exception)
            [nodeContext unhandledException:exception inContext:ctx];
    }
    
    [nodeContext mainLoop:^(int errorCode) {
        exit(errorCode);
    }];
    
    dispatch_main();
    return 0;
}
