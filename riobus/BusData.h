//
//  BusData.h
//  riobus
//
//  Created by Bruno do Amaral on 05/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BusData : NSObject

@property NSDate *lastUpdate ;
@property NSString *order ;
@property NSString *lineNumber ;
@property NSNumber *velocity ;
@property CLLocation *location ;
@property NSNumber *direction ;

+ (NSString*)humanReadableStringForSeconds:(NSInteger)value;
- (NSString*) humanReadableDelay;
- (NSInteger) delayInMinutes ;
- (NSInteger) delayInSeconds ;

@end
