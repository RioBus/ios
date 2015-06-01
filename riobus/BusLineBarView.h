//
//  BusLineBarView.h
//  riobus
//
//  Created by Mario Cecchi on 6/1/15.
//  Copyright (c) 2015 Rio Bus. All rights reserved.
//

#import <UIKit/UIKit.h>
IB_DESIGNABLE
@interface BusLineBarView : UIView

@property (weak, nonatomic) IBOutlet UIView* ibView;
@property (weak, nonatomic) IBOutlet UILabel *busLineLabel;

@end
