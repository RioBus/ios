//
//  BusLineBarView.m
//  riobus
//
//  Created by Mario Cecchi on 6/1/15.
//  Copyright (c) 2015 Rio Bus. All rights reserved.
//

#import "BusLineBarView.h"

@implementation BusLineBarView

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [[NSBundle mainBundle] loadNibNamed:@"BusLineBarView" owner:self options:nil];
        [self addSubview:self.ibView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
