#import <Google/Analytics.h>
#import "ReportDetailViewController.h"

@interface ReportDetailViewController ()

@property (weak, nonatomic) IBOutlet UITextView *problemTextView;
@property (weak, nonatomic) IBOutlet UIView *feedbackView;

@end

@implementation ReportDetailViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    if ([self.problem[@"tipo"] isEqualToString:@"prefeitura"]) {
        self.problemTextView.hidden = NO;
        [self.feedbackView removeFromSuperview];
    }
    else if ([self.problem[@"tipo"] isEqualToString:@"app"] ||
             [self.problem[@"tipo"] isEqualToString:@"outro"]) {
        [self.problemTextView removeFromSuperview];
        self.feedbackView.hidden = NO;
    }
    else {
        NSLog(@"Erro reportando problema (tentando reportar problema de tipo inesperado).");
    }
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"Report"
                                                          action:@"Reportou problema"
                                                           label:self.problem[@"descricao"]
                                                           value:nil] build]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

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
