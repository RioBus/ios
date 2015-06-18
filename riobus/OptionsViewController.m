#import <PSTAlertController/PSTAlertController.h>
#import "OptionsViewController.h"

@interface OptionsViewController ()

@property (weak, nonatomic) IBOutlet UITextView *aboutTextView;

@end

@implementation OptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];

    NSMutableAttributedString *mutable = self.aboutTextView.attributedText.mutableCopy;
    [mutable.mutableString replaceOccurrencesOfString:@"$VERSION" withString:version options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutable.length)];
    [mutable.mutableString replaceOccurrencesOfString:@"$BUILD" withString:build options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutable.length)];
    self.aboutTextView.attributedText = mutable;
    self.aboutTextView.selectable = NO;
}

- (void)viewWillLayoutSubviews {
    // Corrige a posição do scroll que é alterada quando atualiza o texto
    [self.aboutTextView setContentOffset:CGPointZero animated:NO];
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
