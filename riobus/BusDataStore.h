//
//  BusDataStore.h
//  riobus
//
//  Created by Bruno do Amaral on 05/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BusData.h"

@interface BusDataStore : NSObject

+ (BusDataStore*)sharedInstance;

- (NSOperation*)loadBusDataForLineNumber:(NSString*)lineNumber withCompletionHandler:(void (^)(NSArray *busesData, NSError *error)) handler;
- (NSOperation*)loadBusLineShapeForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *)) handler;

@end
