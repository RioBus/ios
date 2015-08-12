#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BusLine.h"

@interface BusLineTests : XCTestCase

@end

@implementation BusLineTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitWithLineAndName {
    BusLine *busLine = [[BusLine alloc] initWithLine:@"485" andName:@"PENHA X GENERAL OSORIO (VIA TUNEL SANTA BARBARA)"];
    
    XCTAssertEqualObjects(busLine.line, @"485");
    XCTAssertEqualObjects(busLine.name, @"Penha X General Osorio (Via Tunel Santa Barbara)", @"Line name was not capitalised properly");
    XCTAssertEqual(busLine.places.count, 2, @"Line should have two place objects");
    XCTAssertEqualObjects(busLine.places[0], @"Penha", @"Line place was not properly parsed");
    XCTAssertEqualObjects(busLine.places[1], @"General Osorio", @"Line place was not properly parsed");
    
    
    busLine = [[BusLine alloc] initWithLine:@"123" andName:@""];
    XCTAssertEqualObjects(busLine.line, @"123");
    XCTAssertNil(busLine.name, @"Line name should be nil when name is empty");
    XCTAssertNil(busLine.places, @"Line places should be nil when name is empty");
    
    busLine = [[BusLine alloc] initWithLine:@"123" andName:nil];
    XCTAssertNil(busLine.name, @"Line name should be nil when name is nil");
    XCTAssertNil(busLine.places, @"Line places should be nil when name is nil");
    
    
    busLine = [[BusLine alloc] initWithLine:@"234" andName:@""];
        XCTAssertNil(busLine.name, @"Line name should be nil when name is 'desconhecido'");
    XCTAssertNil(busLine.places, @"Line places should be nil when name is 'desconhecido'");
    
    
    busLine = [[BusLine alloc] initWithLine:@"345" andName:@"JARDIM BOTANICO (HORTO) X CENTRAL (VIA COPACABANA)"];
    XCTAssertEqualObjects(busLine.name, @"Jardim Botanico (Horto) X Central (Via Copacabana)", @"Line name was not capitalised properly");
    XCTAssertEqual(busLine.places.count, 2, @"Line should have two place objects");
    XCTAssertEqualObjects(busLine.places[0], @"Jardim Botanico", @"Line place was not properly parsed");
    XCTAssertEqualObjects(busLine.places[1], @"Central", @"Line place was not properly parsed");
    
    
    busLine = [[BusLine alloc] initWithLine:@"485" andName:@"GENERAL OSORIO"];
    XCTAssertEqualObjects(busLine.name, @"General Osorio", @"Line name was not capitalised properly");
    XCTAssertNil(busLine.places, @"Line places should be nil when name contains only one location");
    
}

@end
