//
//  BusDataStoreTests.m
//  riobus
//
//  Created by Mario Cecchi on 5/6/15.
//  Copyright (c) 2015 Rio Bus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BusDataStore.h"

@interface BusDataStoreTests : XCTestCase

@end

@implementation BusDataStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        
        XCTAssertNil(busesData, @"busesData should've returned nil with empty line number");
        XCTAssertNotNil(error, @"Operation should have returned an error from server");
        
        waitingForBlock = NO;
        
    }];
    
    // Run the loop
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}

/**
 * Tests if the server is responding normally to a request with an fake line number
 */
- (void)testLoadBusDataFakeLine {
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"ABCDEFGH" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        
        XCTAssertNotNil(busesData, @"busesData returned nil");
        XCTAssert(busesData.count == 0, @"busesData should've returned an empty array");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
        
    }];
    
    // Run the loop
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}

/**
 * Tests if the server is responding normally to a request with an existing line number
 */
- (void)testLoadBusDataRealLine {
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusDataForLineNumber:@"485" withCompletionHandler:^(NSArray *busesData, NSError *error) {
        
        XCTAssertNotNil(busesData, @"busesData returned nil");
        XCTAssert(busesData.count > 0, @"busesData returned an empty array");
        XCTAssertEqualObjects([busesData[0] class], [BusData class], @"busesData does not contain a BusData object");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
        
    }];
    
    // Run the loop
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}



/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeEmpty {
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:@"" withCompletionHandler:^(NSArray *shapes, NSError *error) {
        
        XCTAssertNil(shapes, @"shapes should've returned nil with empty line number");
        XCTAssertNotNil(error, @"Operation should have returned an error from server");
        
        waitingForBlock = NO;
        
    }];
    
    // Run the loop
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}


/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeFakeLine {
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:@"ABCDEFGH" withCompletionHandler:^(NSArray *shapes, NSError *error) {
        
        XCTAssertNotNil(shapes, @"shapes returned nil");
        XCTAssert(shapes.count == 0, @"shapes should've returned an empty array");
        XCTAssertNil(error, @"Operation returned an error");
        
        
        waitingForBlock = NO;
        
    }];
    
    // Run the loop
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}

/**
 * Tests if the server is responding normally to a request with an empty line number
 */
- (void)testLoadBusLineShapeRealLine {
    __block BOOL waitingForBlock = YES;
    
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:@"485" withCompletionHandler:^(NSArray *shapes, NSError *error) {
        
        XCTAssertNotNil(shapes, @"shapes returned nil");
        XCTAssert(shapes.count > 0, @"shapes returned an empty array");
        XCTAssert(((NSArray*)shapes[0]).count > 0, @"shapes does not contain a NSArray object");
        NSArray* shape = shapes[0];
        CLLocation* location = shape[0];
        XCTAssertNotNil(location, @"returned shape object is nil");
        XCTAssertNil(error, @"Operation returned an error");
        
        waitingForBlock = NO;
        
    }];
    
    // Run the loop
    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
}


@end
