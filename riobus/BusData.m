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

- (NSString*)humanReadableDelay{
    NSInteger value = [self delayInSeconds];
    if (value<SECONDS_IN_MINUTE)
        return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"segundo" : @"segundos")];
    
    value/=SECONDS_IN_MINUTE;
    if (value<MINUTES_IN_HOUR)
        return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"minuto" : @"minutos")];
    
    value/=MINUTES_IN_HOUR;
    if (value<HOUR_IN_DAY)
        return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"hora" : @"horas")];
    
    value/=HOUR_IN_DAY;
        return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"dia" : @"dias")];
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
