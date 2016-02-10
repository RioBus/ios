#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "BusData.h"

@interface BusDataTests : XCTestCase

@property (nonatomic) BusData* busData;

@end

@implementation BusDataTests

- (void)setUp {
    [super setUp];
    self.busData = [[BusData alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

/**
 * Tests initialisation from a dictionary
 */
- (void)testInitWithDictionary {
    NSDictionary *dictionary = @{
                                 @"timeStamp": @"2016-02-10T03:00:06.000Z",
                                 @"order": @"B31151",
                                 @"line": @"485",
                                 @"speed": @20,
                                 @"latitude": @-22.8051,
                                 @"longitude": @-43.3098,
                                 @"direction": @176,
                                 @"sense": @"GENERAL OSORIO (VIA TUNEL SANTA BARBARA) X PENHA",
                                 };
    
    NSDateFormatter *jsonDateFormat = [[NSDateFormatter alloc] init];
    jsonDateFormat.dateFormat = @"MM-dd-yyyy HH:mm:ss";
    jsonDateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    BusData *busData = [[BusData alloc] initWithDictionary:dictionary];
    XCTAssertNotNil(busData);
    XCTAssertEqualObjects([jsonDateFormat stringFromDate:busData.lastUpdate], @"02-10-2016 03:00:06");
    XCTAssertEqualObjects(busData.order, dictionary[@"order"]);
    XCTAssertEqualObjects(busData.lineNumber, dictionary[@"line"]);
    XCTAssertEqualObjects(busData.velocity, dictionary[@"speed"]);
    XCTAssertEqual(busData.location.coordinate.latitude, [dictionary[@"latitude"] doubleValue]);
    XCTAssertEqual(busData.location.coordinate.longitude, [dictionary[@"longitude"] doubleValue]);
    XCTAssertEqualObjects(busData.direction, dictionary[@"direction"]);
    XCTAssertEqualObjects(busData.sense, ((NSString *)dictionary[@"sense"]).capitalizedString);
}

/**
 * Tests destination parsing 
 */
- (void)testDestination {
    self.busData.sense = @"GENERAL OSORIO (VIA TUNEL SANTA BARBARA) X PENHA";
    XCTAssertEqualObjects(self.busData.destination, @"Penha");
    
    self.busData.sense = @"GENERAL OSORIO X PENHA";
    XCTAssertEqualObjects(self.busData.destination, @"Penha");
    
    self.busData.sense = @"PENHA X GENERAL OSORIO (VIA TUNEL SANTA BARBARA)";
    XCTAssertEqualObjects(self.busData.destination, @"General Osorio");
    
    self.busData.sense = @"JARDIM BOTANICO (HORTO) X CENTRAL (VIA COPACABANA)";
    XCTAssertEqualObjects(self.busData.destination, @"Central");
    
    self.busData.sense = @"CENTRAL (VIA COPACABANA) X JARDIM BOTANICO (HORTO)";
    XCTAssertEqualObjects(self.busData.destination, @"Jardim Botanico");
    
    self.busData.sense = @"PENHA X GENERAL OSORIO";
    XCTAssertEqualObjects(self.busData.destination, @"General Osorio");
    
    self.busData.sense = @"Penha x General Osorio";
    XCTAssertEqualObjects(self.busData.destination, @"General Osorio");
    
    self.busData.sense = @"";
    XCTAssertNil(self.busData.destination);
    
    self.busData.sense = @"desconhecido";
    XCTAssertNil(self.busData.destination);
    
    self.busData.sense = @"GENERAL OSORIO";
    XCTAssertNil(self.busData.destination);
    
    self.busData.sense = @"GENERAL OSORIO X ";
    XCTAssertNil(self.busData.destination);
}

@end
