//
//  OptionsViewController.h
//  Ônibus Rio
//
//  Created by Vinicius Bittencourt on 28/05/14.
//  Copyright (c) 2014 Vinicius Bittencourt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OptionsViewControllerDelegate <NSObject>
@end

@interface OptionsViewController : UIViewController<UIAlertViewDelegate>

@property (weak, nonatomic) id<OptionsViewControllerDelegate> delegate;

@end
