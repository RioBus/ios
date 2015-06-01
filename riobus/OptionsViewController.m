#import "OptionsViewController.h"

@interface OptionsViewController ()
@end

@implementation OptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (IBAction)clickedClearCacheButton:(id)sender{
    // UIAlertController is not available before iOS 8.0
    if ([UIAlertController class]) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Limpar cache"
                                                                       message:@"Limpando o cache você irá remover os trajetos de linhas de ônibus armazenadas."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancelar" style:UIAlertActionStyleCancel  handler:NULL]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Limpar"   style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self clearCache];
        }]];
        alert.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        // For iOS 7
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Limpar cache"
                              message:@"Limpando o cache você irá remover os trajetos de linhas de ônibus armazenadas."
                              delegate:self
                              cancelButtonTitle:@"Cancelar"
                              otherButtonTitles:@"Limpar", nil];
        
        [alert show];
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self clearCache];
    }
}

- (void)clearCache {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Rotas de Onibus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
