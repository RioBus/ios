//
//  BusData.m
//  riobus
//
//  Created by Bruno do Amaral on 05/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "BusData.h"

#define MINUTES_IN_HOUR     60

@implementation BusData

- (NSInteger)delayInMinutes
{
    return [self delayInSeconds] / MINUTES_IN_HOUR ;
}

- (NSInteger)delayInSeconds
{
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate];
}

@end
