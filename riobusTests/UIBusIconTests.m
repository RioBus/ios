//
//  UIBusIconTests.m
//  riobus
//
//  Created by Mario Cecchi on 5/6/15.
//  Copyright (c) 2015 Rio Bus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "UIBusIcon.h"

@interface UIBusIconTests : XCTestCase

@end

@implementation UIBusIconTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBusIcon {
    UIImage* image = [UIBusIcon iconForBusLine:@"485" withDelay:0 andColor:[UIColor colorWithRed:0.0 green:152.0/255.0 blue:211.0/255.0 alpha:1.0]];
    
    XCTAssertNotNil(image, @"Image returned nil");
    XCTAssertEqual(image.size.width, 64, @"Image width incorrect");
    XCTAssertEqual(image.size.height, 37, @"Image height incorrect");
}

@end
