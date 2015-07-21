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
                                 @"timeStamp": @"06-08-2015 23:40:00",
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
    
    BusData *busData = [[BusData alloc] initWithDictionary:dictionary];
    XCTAssertNotNil(busData);
    XCTAssertEqualObjects([jsonDateFormat stringFromDate:busData.lastUpdate], dictionary[@"timeStamp"]);
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

- (void)testDelayInSeconds {
    self.busData.lastUpdate = [NSDate date];
    XCTAssertEqual([self.busData delayInSeconds], 0);
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-15];
    XCTAssertEqual([self.busData delayInSeconds], 15);
}

- (void)testDelayInMinutes {
    self.busData.lastUpdate = [NSDate date];
    XCTAssertEqual([self.busData delayInMinutes], 0);
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-15];
    XCTAssertEqual([self.busData delayInMinutes], 0);
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-60];
    XCTAssertEqual([self.busData delayInMinutes], 1);
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-200];
    XCTAssertEqual([self.busData delayInMinutes], 3);
}

- (void)testHumanReadableStringForSeconds {
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:0], @"agora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:1], @"agora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:15], @"agora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:59], @"agora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:60], @"agora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:119], @"agora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:120], @"2 minutos atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:3599], @"59 minutos atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:3600], @"1 hora atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:7199], @"1 hora atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:7200], @"2 horas atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:86399], @"23 horas atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:86400], @"1 dia atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:172799], @"1 dia atrás");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:172800], @"2 dias atrás");
}

- (void)testHumanReadableDelay {
    self.busData.lastUpdate = [NSDate date];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"agora");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-15];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"agora");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-60];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"agora");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-180];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"3 minutos atrás");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-3600];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"1 hora atrás");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-7200];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"2 horas atrás");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-86400];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"1 dia atrás");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-172800];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"2 dias atrás");
}

@end
