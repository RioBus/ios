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

- (void)testInitWithDictionary {
    XCTFail(@"Unimplemented");
}

- (void)testDestination {
    XCTFail(@"Unimplemented");
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
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:0], @"0 segundos");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:1], @"1 segundo");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:15], @"15 segundos");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:59], @"59 segundos");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:60], @"1 minuto");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:119], @"1 minuto");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:120], @"2 minutos");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:3599], @"59 minutos");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:3600], @"1 hora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:7199], @"1 hora");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:7200], @"2 horas");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:86399], @"23 horas");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:86400], @"1 dia");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:172799], @"1 dia");
    
    XCTAssertEqualObjects([BusData humanReadableStringForSeconds:172800], @"2 dias");
}

- (void)testHumanReadableDelay {
    self.busData.lastUpdate = [NSDate date];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"0 segundos");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-15];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"15 segundos");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-60];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"1 minuto");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-180];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"3 minutos");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-3600];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"1 hora");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-7200];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"2 horas");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-86400];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"1 dia");
    
    self.busData.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-172800];
    XCTAssertEqualObjects([self.busData humanReadableDelay], @"2 dias");
}

@end
