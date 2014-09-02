//
//  OptionsViewController.h
//  Ônibus Rio
//
//  Created by Vinicius Bittencourt on 28/05/14.
//  Copyright (c) 2014 Vinicius Bittencourt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OptionsViewControllerDelegate <NSObject>

- (void) doneOptionsView;

@end

@interface OptionsViewController : UIViewController<UITextFieldDelegate>

@property (weak, nonatomic) id<OptionsViewControllerDelegate> delegate;

@end
