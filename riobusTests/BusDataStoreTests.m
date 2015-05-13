#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BusDataStore.h"

#define TIMEOUT_SECONDS 10

@interface BusDataStoreTests : XCTestCase

@end

@implementation BusDataStoreTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

/**
 * Tests if the singleton pattern is correctly implemented and returning the same object
 */
- (void)testSingleton {
    XCTAssertEqualObjects([BusDataStore sharedInstance], [BusDataStore sharedInstance]);
}

/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusDataEmpty {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        XCTAssertNil(busesData, @"busesData should've returned nil with empty line number");
        XCTAssertNotNil(error, @"Operation should have returned an error from server");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && [timeout timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

/**
 * Tests if the server is responding normally to a request with an fake line number
 */
- (void)testLoadBusDataFakeLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"ABCDEFGH" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        XCTAssertNotNil(busesData, @"busesData returned nil");
        XCTAssert(busesData.count == 0, @"busesData should've returned an empty array");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && [timeout timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");}

/**
 * Tests if the server is responding normally to a request with an existing line number
 */
- (void)testLoadBusDataRealLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"485" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        XCTAssertNotNil(busesData, @"busesData returned nil");
        XCTAssert(busesData.count > 0, @"busesData returned an empty array");
        XCTAssertEqualObjects([busesData[0] class], [BusData class], @"busesData does not contain a BusData object");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && [timeout timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}



/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeEmpty {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:@"" withCompletionHandler:^(NSArray *shapes, NSError *error) {
        XCTAssertNil(shapes, @"Shapes should've returned nil with empty line number");
        XCTAssertNotNil(error, @"Operation should have returned an error from server");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && [timeout timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}


/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeFakeLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:@"ABCDEFGH" withCompletionHandler:^(NSArray *shapes, NSError *error) {
        XCTAssertNotNil(shapes, @"Shapes returned nil");
        XCTAssert(shapes.count == 0, @"Shapes should've returned an empty array");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && [timeout timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeRealLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:@"485" withCompletionHandler:^(NSArray *shapes, NSError *error) {
        XCTAssertNotNil(shapes, @"Shapes returned nil");
        XCTAssert(shapes.count > 0, @"Shapes returned an empty array");
        XCTAssert(((NSArray*)shapes[0]).count > 0, @"Shapes does not contain a NSArray object");
        NSArray* shape = shapes[0];
        CLLocation* location = shape[0];
        XCTAssertNotNil(location, @"Returned shape object is nil");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && [timeout timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}


@end
