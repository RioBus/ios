#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BusDataStore.h"
#import "BusData.h"

@interface BusDataStoreTests : XCTestCase

@end

@implementation BusDataStoreTests

static const float timeoutInSeconds = 10.0;

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
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        XCTAssertNil(busesData, @"busesData should've returned nil with empty line number");
        XCTAssertNotNil(error, @"Operation should have returned an error from server");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && timeout.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

/**
 * Tests if the server is responding normally to a request with an fake line number
 */
- (void)testLoadBusDataFakeLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"ABCDEFGH" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        XCTAssertNotNil(busesData, @"busesData returned nil");
        XCTAssert(busesData.count == 0, @"busesData should've returned an empty array");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && timeout.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

/**
 * Tests if the server is responding normally to a request with an existing line number
 */
- (void)testLoadBusDataRealLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"636" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        XCTAssertNotNil(busesData, @"busesData returned nil");
        XCTAssert(busesData.count > 0, @"busesData returned an empty array");
        XCTAssertEqualObjects([busesData[0] class], [BusData class], @"busesData does not contain a BusData object");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && timeout.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeFakeLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineItineraryForLineNumber:@"ABCDEFGH" withCompletionHandler:^(NSArray *itinerarySpots, NSError *error) {
        XCTAssertNotNil(itinerarySpots, @"Itinerary spots returned nil");
        XCTAssert(itinerarySpots.count == 0, @"Itinerary spots should've returned an empty array");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && timeout.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeRealLine {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineItineraryForLineNumber:@"636" withCompletionHandler:^(NSArray *itinerarySpots, NSError *error) {
        XCTAssertNotNil(itinerarySpots, @"Itinerary spots returned nil");
        XCTAssert(itinerarySpots.count > 0, @"Itinerary spots returned an empty array");
        
        CLLocation* location = itinerarySpots.firstObject;
        XCTAssertNotNil(location, @"Returned shape object is nil");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
    }];
    
    // Run the loop
    while (waitingForBlock && timeout.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    XCTAssertFalse(waitingForBlock, @"Test failed with timeout.");
}

@end
