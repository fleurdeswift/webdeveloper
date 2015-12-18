//
//  NodeLightTests.m
//  NodeLightTests
//

#import <XCTest/XCTest.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <NodeLight/NodeLight.h>

@interface NodeLightTests : XCTestCase

@end

@implementation NodeLightTests {
    JSContext* _context;
}

- (void)setUp {
    [super setUp];
    
    @autoreleasepool {
        _context = [[JSContext alloc] init];
        JSContextGetNodeContext(_context.JSGlobalContextRef);
        [self loadAndEvaluateScript:@"BaseTest"];
    }
}

- (void)tearDown {
    _context = nil;
    [super tearDown];
}

- (JSValue *)loadAndEvaluateScript:(NSString*)name {
    NSURL* url = [[NSBundle bundleForClass:[self class]] URLForResource:name withExtension:@"js"];
    return [_context evaluateScript:[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL] withSourceURL:url];
}

- (NSString *)exceptionDescription:(JSValue *)exception {
    if (exception.isUndefined)
        return @"<undefined>";
    
    JSValue *fileName = exception[@"sourceURL"];
    JSValue *line = exception[@"line"];
    NSString *exceptionStr = [exception toString];
    
    if (!fileName.isUndefined && !line.isUndefined)
        return [NSString stringWithFormat:@"%@ (%@:%@)", exceptionStr, [NSURL URLWithString:[fileName toString]].pathComponents.lastObject, line];
    return exceptionStr;
}

- (void)testBuffer {
    JSValue* jsException = [self loadAndEvaluateScript:@"BufferTest"];
    XCTAssertTrue([jsException isUndefined], @"%@", [self exceptionDescription:jsException]);
}

- (void)testProcess {
    JSValue* jsException = [self loadAndEvaluateScript:@"ProcessTest"];
    XCTAssertTrue([jsException isUndefined], @"%@", [self exceptionDescription:jsException]);
}

- (void)testFS {
    JSValue* jsException = [self loadAndEvaluateScript:@"FSTest"];
    XCTAssertTrue([jsException isUndefined], @"%@", [self exceptionDescription:jsException]);
}

@end
