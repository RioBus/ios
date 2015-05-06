//
//  UIBusIcon.h
//  riobus
//
//  Created by Vitor Marques de Miranda on 01/11/14.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBusIcon : UIImage

+ (UIImage*)iconForBusLine:(NSString*)busLine withDelay:(NSInteger)delayInformation andColor:(UIColor*)color;

@end
