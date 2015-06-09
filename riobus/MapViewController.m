#import <GLKit/GLKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import <Toast/UIView+Toast.h>
#import <GoogleMaps/GoogleMaps.h>
#import "MapViewController.h"
#import "BusDataStore.h"
#import "OptionsViewController.h"
#import "BusSuggestionsTable.h"
#import "BusLineBar.h"

@interface MapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, OptionsViewControllerDelegate, UISearchBarDelegate, BusLineBarDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSMutableDictionary *markerForOrder;
@property (nonatomic) NSArray *busesData;
@property (nonatomic) NSMutableArray *searchedLines;
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) NSArray *availableColors;
@property (nonatomic) NSMutableDictionary *lineColor;
@property (nonatomic) GMSCoordinateBounds *mapBounds;
@property (nonatomic) NSMutableArray *lastRequests;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak, nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak, nonatomic) IBOutlet BusLineBar *busLineBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property (nonatomic) int hasRepositionedMapTimes;
@property (nonatomic) BOOL lastUpdateWasOk;
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
    
    self.busLineBar.delegate = self;
    
    [self.searchInput setBackgroundImage:[UIImage new]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
    
    self.availableColors = @[[UIColor colorWithRed:243.0/255.0 green:102.0/255.0 blue:32.0/255.0 alpha:1.0],
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
    
    // TODO: funcionalidade de busca favorita
}


#pragma mark BusLineBarViewDelegate methods

- (BOOL)busLineBarView:(BusLineBar *)sender didSelectDestination:(NSString *)destination {
    NSLog(@"Selecionou destino %@", destination);
    
    // TODO: filtrar ônibus exibidos no mapa
    // TODO: salvar no histórico o último sentido selecionado
    
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
                                                                         [self.view hideToastActivity];
                                                                         
                                                                         if (error.code != NSURLErrorCancelled) { // Erro ao cancelar um request
                                                                             [self.view makeToast:@"Erro buscando posição dos ônibus."];
                                                                         }
                                                                         
                                                                         self.busesData = nil;
                                                                     }
                                                                     else {
                                                                         self.busesData = busesData;
                                                                         
                                                                         if (!self.busesData.count) {
                                                                             [self.busLineBar hide];
                                                                             [self.view hideToastActivity];
                                                                             
                                                                             NSString *msg = [NSString stringWithFormat:@"Nenhum ônibus encontrado para a linha %@. ", busLineNumber];
                                                                             
                                                                             [self.view makeToast:msg];
                                                                             
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

- (void)setBusesData:(NSArray*)busesData {
    _busesData = busesData;
    [self updateMarkers];
}


#pragma mark Carregamento do marcadores, da rota e do mapa

- (void)insertRouteOfBus:(NSString*)lineName {
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
                                                         NSLog(@"ERRO: Nenhuma rota para exibir");
                                                     }
                                                 }];
}

- (void)updateMarkers {
    for (BusData *busData in self.busesData) {
        // Busca o marcador no mapa se já existir
        GMSMarker *marca = self.markerForOrder[busData.order];
        if (!marca) {
            marca = [[GMSMarker alloc] init];
            [marca setMap:self.mapView];
            [self.markerForOrder setValue:marca forKey:busData.order];
        }
        
        marca.snippet = [NSString stringWithFormat:@"Ordem: %@\nVelocidade: %.0f km/h\nAtualizado há %@", busData.order, [busData.velocity doubleValue], [busData humanReadableDelay]];
        marca.title = busData.sense;
        marca.position = busData.location.coordinate;
        marca.icon = [UIImage imageNamed:@"BusMarker"];
        
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


#pragma mark UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
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
    NSCharacterSet* splitCharacters = [[NSCharacterSet characterSetWithCharactersInString:validCharacters] invertedSet];
    self.searchedLines = [[[searchBar.text uppercaseString] componentsSeparatedByCharactersInSet:splitCharacters] mutableCopy];
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

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar {
    [self.searchInput becomeFirstResponder];
    [self setSuggestionsTableVisible:YES];
    [self cancelCurrentRequests];
    [self.view hideToastActivity];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    [self.searchInput resignFirstResponder];
    [self setSuggestionsTableVisible:NO];
}


#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = [locations lastObject];
    [self.mapView animateToLocation:location.coordinate];
    [self.mapView animateToZoom:cameraCurrentLocationZoomLevel];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error %@", error.description);
}

#pragma mark Segue control

/**
 * Prepara os segues disparados pelo Storyboard
 */
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewOptions"]) {
        OptionsViewController *optionsVC = segue.destinationViewController;
        optionsVC.delegate = self;
    }
}


#pragma mark Listeners de notificações

/**
 * Atualiza o tamanho da tabela de acordo com o tamanho do teclado
 */
- (void)keyboardWillShow:(NSNotification *)sender {
    CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardBottomConstraint.constant = keyboardFrame.size.height;
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
