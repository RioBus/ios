//
//  OptionsViewController.m
//  Ônibus Rio
//
//  Created by Vinicius Bittencourt on 28/05/14.
//  Copyright (c) 2014 Vinicius Bittencourt. All rights reserved.
//

#import "OptionsViewController.h"

@interface OptionsViewController ()
@end

@implementation OptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction)clearCache:(id)sender{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Limpar Cache"
                                                    message:@"Limpando a cache você irá remover os trajetos de linhas de ônibus armazenadas."
                                             preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel  handler:NULL]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Limpar"   style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Rotas de Onibus"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }]];
    
    alert.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)closeAboutWindow:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
