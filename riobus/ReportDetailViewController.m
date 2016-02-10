#import <Google/Analytics.h>
#import "ReportDetailViewController.h"

@interface ReportDetailViewController ()

@end

@implementation ReportDetailViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    if ([self.problem[@"tipo"] isEqualToString:@"prefeitura"]) {
        self.problemTitleLabel.text = NSLocalizedString(@"ISSUE_CITY_HALL_TITLE", nil);
        self.problemMessageLabel.text = NSLocalizedString(@"ISSUE_CITY_HALL_MESSAGE", nil);
        
        [self.sendMessageButton performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
    }
    else if ([self.problem[@"tipo"] isEqualToString:@"app"] ||
             [self.problem[@"tipo"] isEqualToString:@"outro"]) {
        self.problemTitleLabel.text = NSLocalizedString(@"ISSUE_APP_TITLE", nil);
        self.problemMessageLabel.text = NSLocalizedString(@"ISSUE_APP_MESSAGE", nil);
    }
    else {
        NSLog(@"Error reporting issue (unexpected issue type received)");
    }
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Report"
                                                          action:@"Reportou problema"
                                                           label:self.problem[@"descricao"]
                                                           value:nil] build]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - IBActions

- (IBAction)didTapCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapMessageButton:(id)sender {
    NSURL *fbURL = [[NSURL alloc] initWithString:@"fb://profile/1408367169433222"];
    // Verifica se o usuário possui o app do Facebook instalado. Caso contrário, abre a página normalmente no Safari.
    if (![[UIApplication sharedApplication] canOpenURL:fbURL]) {
        fbURL = [[NSURL alloc] initWithString:@"https://www.facebook.com/RioBusOficial"];
    }
    
    [[UIApplication sharedApplication] openURL:fbURL];
}

@end
