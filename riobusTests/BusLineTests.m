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

- (void)testInitWithNameAndDescription {
    BusLine *busLine = [[BusLine alloc] initWithName:@"485" andDescription:@"PENHA X GENERAL OSORIO (VIA TUNEL SANTA BARBARA)"];
    
    XCTAssertEqualObjects(busLine.name, @"485");
    XCTAssertEqualObjects(busLine.lineDescription, @"Penha X General Osorio (Via Tunel Santa Barbara)", @"Line name was not capitalised properly");
    XCTAssertEqual(busLine.places.count, 2, @"Line should have two place objects");
    XCTAssertEqualObjects(busLine.places[0], @"Penha", @"Line place was not properly parsed");
    XCTAssertEqualObjects(busLine.places[1], @"General Osorio", @"Line place was not properly parsed");
    
    
    busLine = [[BusLine alloc] initWithName:@"123" andDescription:@""];
    XCTAssertEqualObjects(busLine.name, @"123");
    XCTAssertNil(busLine.lineDescription, @"Line name should be nil when name is empty");
    XCTAssertNil(busLine.places, @"Line places should be nil when name is empty");
    
    busLine = [[BusLine alloc] initWithName:@"123" andDescription:nil];
    XCTAssertNil(busLine.lineDescription, @"Line name should be nil when name is nil");
    XCTAssertNil(busLine.places, @"Line places should be nil when name is nil");
    
    
    busLine = [[BusLine alloc] initWithName:@"234" andDescription:@""];
        XCTAssertNil(busLine.lineDescription, @"Line name should be nil when name is 'desconhecido'");
    XCTAssertNil(busLine.places, @"Line places should be nil when name is 'desconhecido'");
    
    
    busLine = [[BusLine alloc] initWithName:@"345" andDescription:@"JARDIM BOTANICO (HORTO) X CENTRAL (VIA COPACABANA)"];
    XCTAssertEqualObjects(busLine.lineDescription, @"Jardim Botanico (Horto) X Central (Via Copacabana)", @"Line name was not capitalised properly");
    XCTAssertEqual(busLine.places.count, 2, @"Line should have two place objects");
    XCTAssertEqualObjects(busLine.places[0], @"Jardim Botanico", @"Line place was not properly parsed");
    XCTAssertEqualObjects(busLine.places[1], @"Central", @"Line place was not properly parsed");
    
    
    busLine = [[BusLine alloc] initWithName:@"485" andDescription:@"GENERAL OSORIO"];
    XCTAssertEqualObjects(busLine.lineDescription, @"General Osorio", @"Line name was not capitalised properly");
    XCTAssertNil(busLine.places, @"Line places should be nil when name contains only one location");
    
}

@end
