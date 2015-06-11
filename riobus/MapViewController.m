#import <Toast/UIView+Toast.h>
#import <GoogleMaps/GoogleMaps.h>
#import <PSTAlertController/PSTAlertController.h>
#import "MapViewController.h"
#import "BusDataStore.h"
#import "OptionsViewController.h"
#import "BusSuggestionsTable.h"
#import "BusLineBar.h"
#import "riobus-Swift.h"

@interface MapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, OptionsViewControllerDelegate, UISearchBarDelegate, BusLineBarDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSMutableDictionary *markerForOrder;
@property (nonatomic) NSArray *busesData;
@property (nonatomic) NSDictionary *busLineInformation;
@property (nonatomic) NSMutableArray *searchedLines;
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) NSArray *availableColors;
@property (nonatomic) NSMutableDictionary *lineColor;
@property (nonatomic) GMSCoordinateBounds *mapBounds;
@property (nonatomic) NSMutableArray *lastRequests;
@property (nonatomic) int hasRepositionedMapTimes;
@property (nonatomic) BOOL lastUpdateWasOk;
@property (nonatomic) CGFloat suggestionTableBottomSpacing;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak, nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak, nonatomic) IBOutlet BusLineBar *busLineBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *menuMiddleButton;
@property (weak, nonatomic) IBOutlet UIButton *menuRightButton;
@property (weak, nonatomic) IBOutlet UIButton *menuLeftButton;

@end

static const CGFloat cameraDefaultLatitude = -22.9043527;
static const CGFloat cameraDefaultLongitude = -43.1912805;
static const CGFloat cameraDefaultZoomLevel = 12.0;
static const CGFloat cameraCurrentLocationZoomLevel = 14.0;
static const CGFloat cameraPaddingTop = 80.0;
static const CGFloat cameraPaddingLeft = 50.0;
static const CGFloat cameraPaddingBottom = 120.0;
static const CGFloat cameraPaddingRight = 50.0;

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.markerForOrder = [[NSMutableDictionary alloc] initWithCapacity:100];
    self.lineColor = [[NSMutableDictionary alloc] init];
    self.searchedLines = [[NSMutableArray alloc] init];
    self.lastRequests = [[NSMutableArray alloc] init];
    
    self.mapView.mapType = kGMSTypeNormal;
    self.mapView.myLocationEnabled = YES;
    
    self.suggestionTable.searchInput = self.searchInput;
    self.suggestionTable.alpha = 0;
    
    [self.menuLeftButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.menuRightButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.menuMiddleButton setBackgroundTintColor:[UIColor appLightBlueColor] state:UIControlStateHighlighted];
    [self.menuMiddleButton setBackgroundTintColor:[UIColor appDarkBlueColor] state:UIControlStateNormal];
    
    self.busLineBar.delegate = self;
    
    self.searchInput.backgroundImage = [UIImage new];
    [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil].tintColor = [UIColor whiteColor];
    
    self.availableColors = @[[UIColor appOrangeColor],
                             [UIColor colorWithRed:0.0 green:152.0/255.0 blue:211.0/255.0 alpha:1.0],
                             [UIColor orangeColor],
                             [UIColor purpleColor],
                             [UIColor brownColor],
                             [UIColor cyanColor],
                             [UIColor magentaColor],
                             [UIColor blackColor],
                             [UIColor blueColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:cameraDefaultLatitude
                                                      longitude:cameraDefaultLongitude
                                                           zoom:cameraDefaultZoomLevel];
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        
        // This checks for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
    return _locationManager;
}

#pragma mark Menu actions

- (IBAction)informationMenuButtonTapped:(id)sender {
    [self performSegueWithIdentifier:@"viewOptions" sender:self];
}

- (IBAction)locationMenuButtonTapped:(id)sender {
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    }
    else {
        NSLog(@"Location services not enabled");
    }
}

- (IBAction)favoriteMenuButtonTapped:(id)sender {
    NSLog(@"Favorite manu tapped");
    
    // TODO: Implementar funcionalidade de busca favorita
}


#pragma mark BusLineBarViewDelegate methods

- (BOOL)busLineBarView:(BusLineBar *)sender didSelectDestination:(NSString *)destination {
    NSLog(@"Selecionou destino %@", destination);
    
    // TODO: Filtrar ônibus exibidos no mapa
    // TODO: Salvar no histórico o último sentido selecionado
    
    return YES;
}


#pragma mark Controller methods

/**
 * Cancelar todas as requisições pendentes
 */
- (void)cancelCurrentRequests {
    if (self.lastRequests) {
        for (NSOperation* request in self.lastRequests) {
            [request cancel];
        }
    }
    
    [self.lastRequests removeAllObjects];
}

/**
 * Cancelar todos os timers ativos
 */
- (void)cancelActiveTimers {
    if (self.updateTimer) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}


#pragma mark Carregamento do marcadores, da rota e do mapa

/**
 * Atualiza os dados para o carregamento do mapa
 */
- (void)updateSearchedBusesData:(id)sender {
    if ([self.searchInput isFirstResponder] || !self.searchedLines.count) {
        return;
    }
    
    [self cancelActiveTimers];
    [self cancelCurrentRequests];
    
    // Load bus data for each searched line
    for (NSString *busLineNumber in self.searchedLines) {
        NSOperation *request = [[BusDataStore sharedInstance] loadBusDataForLineNumber:busLineNumber
                                                                 withCompletionHandler:^(NSArray *busesData, NSError *error) {
                                                                     if (error) {
                                                                         [self.busLineBar hide];
                                                                         [self.view hideToastActivity];
                                                                         
                                                                         if (error.code != NSURLErrorCancelled) { // Erro ao cancelar um request
                                                                             
                                                                             PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Erro" message:@"Não foi possível buscar a posição dos ônibus."];
                                                                             [alertController addAction:[PSTAlertAction actionWithTitle:@"OK" style:PSTAlertActionStyleDefault handler:nil]];
                                                                             [alertController showWithSender:sender controller:self animated:YES completion:nil];
                                                                             
                                                                             self.lastUpdateWasOk = NO;
                                                                         }
                                                                         
                                                                         self.busesData = nil;
                                                                     }
                                                                     else {
                                                                         if (busesData.count > 0) {
                                                                             self.busesData = busesData;
                                                                         }
                                                                         else {
                                                                             self.busesData = nil;
                                                                             [self.busLineBar hide];
                                                                             [self.view hideToastActivity];
                                                                             
                                                                             PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Erro" message:[NSString stringWithFormat:@"Nenhum ônibus encontrado para a linha %@. ", busLineNumber]];
                                                                             [alertController addAction:[PSTAlertAction actionWithTitle:@"Ok" style:PSTAlertActionStyleDefault handler:nil]];
                                                                             [alertController showWithSender:sender controller:self animated:YES completion:nil];
                                                                             
                                                                             self.lastUpdateWasOk = NO;
                                                                         }
                                                                     }
                                                                 }];
        
        [self.lastRequests addObject:request];
    }
    
    [self cancelActiveTimers];
    
    if (self.lastUpdateWasOk) {
        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15
                                                            target:self
                                                          selector:@selector(updateSearchedBusesData:)
                                                          userInfo:nil
                                                           repeats:NO];
    }
}

/**
 * Atualiza a propriedade busesData e os marcadores dos ônibus no mapa.
 * @param busesData Array de BusData contendo as informações dos ônibus pesquisados.
 */
- (void)setBusesData:(NSArray *)busesData {
    _busesData = busesData;

    // Atualizar marcadores
    for (BusData *busData in busesData) {
        // Busca o marcador no mapa se já existir
        GMSMarker *marca = self.markerForOrder[busData.order];
        if (!marca) {
            marca = [[GMSMarker alloc] init];
            marca.map = self.mapView;
            marca.icon = [UIImage imageNamed:@"BusMarker"];
            self.markerForOrder[busData.order] = marca;
        }
        
        marca.snippet = [NSString stringWithFormat:@"Ordem: %@\nVelocidade: %.0f km/h\nAtualizado há %@", busData.order, busData.velocity.doubleValue, busData.humanReadableDelay];
        marca.title = busData.sense;
        marca.position = busData.location.coordinate;
        
        self.mapBounds = [self.mapBounds includingCoordinate:marca.position];
    }
    
    if (self.hasRepositionedMapTimes < self.searchedLines.count) {
        UIEdgeInsets mapBoundsInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.searchInput.frame) + cameraPaddingTop,
                                                        cameraPaddingRight,
                                                        cameraPaddingBottom,
                                                        cameraPaddingLeft);
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:self.mapBounds withEdgeInsets:mapBoundsInsets]];
        
        self.hasRepositionedMapTimes++;
    }
    
    if (self.hasRepositionedMapTimes == self.searchedLines.count) {
        [self.view hideToastActivity];
    }
}

- (void)insertRouteOfBus:(NSString *)lineName {
    [[BusDataStore sharedInstance] loadBusLineInformationForLineNumber:lineName
                                                 withCompletionHandler:^(NSDictionary *busLineInformation, NSError *error) {
                                                     if (!error) {
                                                         [self.busLineBar appearWithBusLine:busLineInformation];
                                                         
                                                         NSArray *shapes = busLineInformation[@"shapes"];
                                                         for (NSMutableArray *shape in shapes) {
                                                             GMSMutablePath *gmShape = [GMSMutablePath path];
                                                             
                                                             for (CLLocation *location in shape) {
                                                                 [gmShape addCoordinate:location.coordinate];
                                                             }
                                                             
                                                             GMSPolyline *polyLine = [GMSPolyline polylineWithPath:gmShape];
                                                             polyLine.strokeColor = self.lineColor[lineName];
                                                             polyLine.strokeWidth = 2.0;
                                                             polyLine.map = self.mapView;
                                                         }
                                                     }
                                                     else {
                                                         self.busLineInformation = nil;
                                                         NSLog(@"ERRO: Nenhuma rota para exibir");
                                                     }
                                                 }];
}


#pragma mark UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchInput resignFirstResponder];
    [self.searchInput setShowsCancelButton:NO animated:YES];
    [self.markerForOrder removeAllObjects];
    [self.mapView clear];
    self.mapBounds = [[GMSCoordinateBounds alloc] init];
    [self setSuggestionsTableVisible:NO];
    self.hasRepositionedMapTimes = 0;
    
    [self.view makeToastActivity];
    
    // Escape search input
    NSString* validCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    NSCharacterSet* splitCharacters = [NSCharacterSet characterSetWithCharactersInString:validCharacters].invertedSet;
    self.searchedLines = [[(searchBar.text).uppercaseString componentsSeparatedByCharactersInSet:splitCharacters] mutableCopy];
    [self.searchedLines removeObject:@""];
    
    // Save search to history
    [self.suggestionTable addToRecentTable:[self.searchedLines componentsJoinedByString:@", "]];
    
    // Draw itineraries
    [self.lineColor removeAllObjects];
    
    int colorIndex = -1;
    for (NSString* busLineNumber in self.searchedLines) {
        colorIndex = (colorIndex+1) % self.availableColors.count;
        self.lineColor[busLineNumber] = self.availableColors[colorIndex];
        
        [self insertRouteOfBus:busLineNumber];
    }
    
    // Call updater
    self.lastUpdateWasOk = YES;
    [self updateSearchedBusesData:self];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchInput becomeFirstResponder];
    [self setSuggestionsTableVisible:YES];
    [self.busLineBar hide];
    [self cancelCurrentRequests];
    [self.view hideToastActivity];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchInput resignFirstResponder];
    [self setSuggestionsTableVisible:NO];
}


#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = locations.lastObject;
    [self.mapView animateToLocation:location.coordinate];
    [self.mapView animateToZoom:cameraCurrentLocationZoomLevel];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error %@", error.description);
}

#pragma mark Segue control

/**
 * Prepara os segues disparados pelo Storyboard.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewOptions"]) {
        OptionsViewController *optionsVC = segue.destinationViewController;
        optionsVC.delegate = self;
    }
}


#pragma mark Listeners de notificações

/**
 * Atualiza o tamanho da tabela de acordo com o tamanho do teclado.
 */
- (void)keyboardWillShow:(NSNotification *)sender {
    CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.suggestionTableBottomSpacing = self.keyboardBottomConstraint.constant;
    self.keyboardBottomConstraint.constant = keyboardFrame.size.height;
    [self.suggestionTable layoutIfNeeded];
}

- (void)keyboardWillHide:(NSNotification *)sender {
    self.keyboardBottomConstraint.constant = self.suggestionTableBottomSpacing;
    [self.suggestionTable layoutIfNeeded];
}

- (void)appDidEnterBackground:(NSNotification *)sender {
    // Cancela o timer para não ficar gastando bateria no background
    [self cancelActiveTimers];
}

- (void)appWillEnterForeground:(NSNotification *)sender {
    [self performSelector:@selector(updateSearchedBusesData:) withObject:self];
}


#pragma mark Funções utilitárias

- (void)setSuggestionsTableVisible:(BOOL)visible {
    static const float animationDuration = 0.2;
    
    if (visible) {
        // Appear
        [self.searchInput setShowsCancelButton:YES animated:YES];
        [UIView animateWithDuration:animationDuration animations:^{
            self.suggestionTable.alpha = 1.0;
        }];
    }
    else {
        // Disappear
        [self.searchInput setShowsCancelButton:NO animated:YES];
        [UIView animateWithDuration:animationDuration animations:^{
            self.suggestionTable.alpha = 0.0;
        }];
    }
}

@end
