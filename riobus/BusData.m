//
//  BusData.m
//  riobus
//
//  Created by Bruno do Amaral on 05/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "BusData.h"

#define MINUTES_IN_HOUR 60

@implementation BusData

- (NSString*)humanReadableDelay{
    NSInteger value = [self delayInSeconds];
    if (value<60)
        return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"segundo" : @"segundos")];
    
    value/=60;
    if (value<60)
        return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"minuto" : @"minutos")];
    
    value/=60;
    return [NSString stringWithFormat:@"%ld %@",value,(value == 1 ? @"hora" : @"horas")];
}

- (NSInteger)delayInMinutes {
    return [self delayInSeconds]/MINUTES_IN_HOUR;
}

- (NSInteger)delayInSeconds {
    NSInteger result = [[NSDate date] timeIntervalSinceDate:self.lastUpdate];

    if ([[[NSCalendar currentCalendar] timeZone] isDaylightSavingTime])
        result-=3600;

    return result;
}

@end
