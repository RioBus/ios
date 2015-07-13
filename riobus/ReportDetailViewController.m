#import "ReportDetailViewController.h"

@interface ReportDetailViewController ()

@property (weak, nonatomic) IBOutlet UITextView *detailTextView;

@end

@implementation ReportDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.problem[@"tipo"] isEqualToString:@"prefeitura"]) {
        NSLog(@"Reportando problema do tipo prefeitura");
    }
    else if ([self.problem[@"tipo"] isEqualToString:@"app"] ||
             [self.problem[@"tipo"] isEqualToString:@"outro"]) {
        NSLog(@"Reportando problema do tipo app/outro");
    }
    else {
        NSLog(@"Erro reportando problema");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)didTapCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
