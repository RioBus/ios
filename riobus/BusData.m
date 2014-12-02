//
//  BusData.m
//  riobus
//
//  Created by Bruno do Amaral on 05/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "BusData.h"

#define SECONDS_IN_MINUTE 60
#define MINUTES_IN_HOUR   60
#define HOUR_IN_DAY       24

@implementation BusData

+ (NSString*)humanReadableStringForTime:(NSInteger)value ofType:(NSString*)type{
    return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? type : [type stringByAppendingString:@"s"])];
}

+ (NSString*)humanReadableStringForSeconds:(NSInteger)value{
    if (value<SECONDS_IN_MINUTE)
        return [BusData humanReadableStringForTime:value ofType:"segundo"];
    
    value/=SECONDS_IN_MINUTE;
    if (value<MINUTES_IN_HOUR)
        return [BusData humanReadableStringForTime:value ofType:"minuto"];
    
    value/=MINUTES_IN_HOUR;
    if (value<HOUR_IN_DAY)
        return [BusData humanReadableStringForTime:value ofType:"hora"];
    
    value/=HOUR_IN_DAY;
    return [BusData humanReadableStringForTime:value ofType:"dia"];
}

- (NSString*)humanReadableDelay{
    return [BusData humanReadableStringForSeconds:[self delayInSeconds]];
}

- (NSInteger)delayInMinutes {
    return [self delayInSeconds]/SECONDS_IN_MINUTE;
}

- (NSInteger)delayInSeconds {
    NSInteger result = [[NSDate date] timeIntervalSinceDate:self.lastUpdate];

    if ([[[NSCalendar currentCalendar] timeZone] isDaylightSavingTime])
        result-=SECONDS_IN_MINUTE*MINUTES_IN_HOUR;

    return result;
}

@end
