//
//  OptionsViewController.m
//  Ônibus Rio
//
//  Created by Vinicius Bittencourt on 28/05/14.
//  Copyright (c) 2014 Vinicius Bittencourt. All rights reserved.
//

#import "OptionsViewController.h"

@interface OptionsViewController ()
@property (strong, nonatomic) IBOutlet UIButton *buttonClose;

@property (strong, nonatomic) IBOutlet UISegmentedControl *tupo;
@property (strong, nonatomic) IBOutlet UISwitch *traf;
@property (strong, nonatomic) IBOutlet UIButton *fbbutton;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation OptionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
   NSInteger myInt = [prefs integerForKey:@"Tipo"];
    if (myInt == 0){
        self.tupo.selectedSegmentIndex = 0;
    }else{
        self.tupo.selectedSegmentIndex = 1;
    }
    
        
    BOOL trafego = [prefs boolForKey:@"Transito"];
    self.traf.on = trafego;
    

    self.buttonClose.layer.cornerRadius = 10;
    self.fbbutton.layer.cornerRadius = 10;
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.textView flashScrollIndicators];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fb:(id)sender {
    NSURL *url = [NSURL URLWithString:@"fb://profile/1408367169433222"];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([self.tupo selectedSegmentIndex] == 0){
      [prefs setInteger:0 forKey:@"Tipo"];
    }
    else if([self.tupo selectedSegmentIndex] == 1){
      [prefs setInteger:1 forKey:@"Tipo"];
    }
    
    [prefs setBool:self.traf.on forKey:@"Transito"];
    // – setBool:forKey:
    // – setFloat:forKey:
    // in your case

    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.delegate doneOptionsView];
}

@end
