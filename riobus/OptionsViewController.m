#import <Google/Analytics.h>
#import <PSTAlertController/PSTAlertController.h>
#import "OptionsViewController.h"

@implementation OptionsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];

    NSMutableAttributedString *mutable = self.aboutTextView.attributedText.mutableCopy;
    [mutable.mutableString replaceOccurrencesOfString:@"$VERSION" withString:version options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutable.length)];
    [mutable.mutableString replaceOccurrencesOfString:@"$BUILD" withString:build options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutable.length)];
    self.aboutTextView.attributedText = mutable;
    self.aboutTextView.selectable = NO;
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Informações"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)viewWillLayoutSubviews {
    // Corrige a posição do scroll que é alterada quando atualiza o texto
    [self.aboutTextView setContentOffset:CGPointZero animated:NO];
}

- (IBAction)didTapFacebookButton:(id)sender {
    NSURL *fbURL = [[NSURL alloc] initWithString:@"fb://profile/1408367169433222"];
    // Verifica se o usuário possui o app do Facebook instalado. Caso contrário, abre a página normalmente no Safari.
    if (![[UIApplication sharedApplication] canOpenURL:fbURL]) {
        fbURL = [[NSURL alloc] initWithString:@"https://www.facebook.com/RioBusOficial"];
    }
    
    [[UIApplication sharedApplication] openURL:fbURL];
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
