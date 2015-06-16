#import <PSTAlertController/PSTAlertController.h>
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

- (IBAction)didTapCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapClearCacheButton:(id)sender {
    PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Limpar o cache" message:@"Limpando o cache você irá remover os trajetos de linhas de ônibus armazenadas."];
    [alertController addAction:[PSTAlertAction actionWithTitle:@"Cancelar" style:PSTAlertActionStyleCancel handler:nil]];
    [alertController addAction:[PSTAlertAction actionWithTitle:@"Limpar" style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        [self clearCache];
    }]];
    [alertController showWithSender:sender controller:self animated:YES completion:nil];
}

- (void)clearCache {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Rotas de Onibus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
