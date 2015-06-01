#import <GLKit/GLKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import <Toast/UIView+Toast.h>
#import <GoogleMaps/GoogleMaps.h>
#import "MapViewController.h"
#import "BusDataStore.h"
#import "OptionsViewController.h"
#import "BusSuggestionsTable.h"
#import "UIBusIcon.h"

@interface MapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, OptionsViewControllerDelegate, UISearchBarDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableDictionary *markerForOrder;
@property (strong, nonatomic) NSArray *busesData;
@property (strong, nonatomic) NSMutableArray* searchedLines;
@property (strong, nonatomic) NSTimer *updateTimer;
@property (strong, nonatomic) NSArray *availableColors;
@property (strong, nonatomic) NSMutableDictionary *lineColor;
@property (strong, atomic   ) GMSCoordinateBounds* mapBounds;
@property (strong, nonatomic) NSMutableArray *lastRequests;
@property (weak,   nonatomic) IBOutlet GMSMapView *mapView;
@property (weak,   nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak,   nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak,   nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property int hasRepositionedMapTimes;

@end

static const CGFloat cameraDefaultLatitude = -22.9043527f;
static const CGFloat cameraDefaultLongitude = -43.1912805f;
static const CGFloat cameraDefaultZoomLevel = 12.0f;
static const CGFloat cameraCurrentLocationZoomLevel = 14.0f;
static const CGFloat cameraPaddingTop = 50.0f;
static const CGFloat cameraPaddingLeft = 50.0f;
static const CGFloat cameraPaddingBottom = 50.0f;
static const CGFloat cameraPaddingRight = 50.0f;

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
    
    [self.searchInput setBackgroundImage:[UIImage new]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
    
    [self startLocationServices];
    
    self.availableColors = @[[UIColor colorWithRed:243.0/255.0 green:102.0/255.0 blue:32.0/255.0 alpha:1.0],
                             [UIColor colorWithRed:0.0 green:152.0/255.0 blue:211.0/255.0 alpha:1.0],
                             [UIColor orangeColor],
                             [UIColor purpleColor],
                             [UIColor brownColor],
                             [UIColor cyanColor],
                             [UIColor magentaColor],
                             [UIColor blackColor],
                             [UIColor blueColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:cameraDefaultLatitude
                                                      longitude:cameraDefaultLongitude
                                                           zoom:cameraDefaultZoomLevel];
    
}


#pragma mark Menu actions

- (IBAction)informationMenuButtonTapped:(id)sender {
    [self performSegueWithIdentifier:@"viewOptions" sender:self];
}

- (IBAction)locationMenuButtonTapped:(id)sender {
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services not enabled");
    }
}

- (IBAction)favoriteMenuButtonTapped:(id)sender {
    NSLog(@"Favorite manu tapped");
}


#pragma mark Controller methods

- (void)startLocationServices {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // This checks for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

/**
 * Cancelar todas as requisições pendentes
 */
- (void)stopCurrentRequests {
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
- (void)stopActiveTimers {
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
    
    [self stopActiveTimers];
    [self stopCurrentRequests];
    
    // Load bus data for each searched line
    for (NSString* busLineNumber in self.searchedLines) {
        NSOperation* request = [[BusDataStore sharedInstance] loadBusDataForLineNumber:busLineNumber
                                                                 withCompletionHandler:^(NSArray *busesData, NSError *error) {
                                                                     if (error) {
                                                                         [self.view hideToastActivity];
                                                                         
                                                                         if (error.code != NSURLErrorCancelled) { // Erro ao cancelar um request
                                                                             [self.view makeToast:[error localizedDescription]];
                                                                         }
                                                                         self.busesData = nil;
                                                                     } else {
                                                                         self.busesData = busesData;
                                                                         
                                                                         if (!self.busesData.count) {
                                                                             [self.view hideToastActivity];
                                                                             NSString *msg = [NSString stringWithFormat:@"Nenhum resultado para a linha %@", busLineNumber];
                                                                             
                                                                             [self.view makeToast:msg];
                                                                         }
                                                                     }
                                                                 }];
        
        [self.lastRequests addObject:request];
    }
    
    [self stopActiveTimers];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(updateSearchedBusesData:) userInfo:nil repeats:NO];
}

- (void)setBusesData:(NSArray*)busesData {
    _busesData = busesData;
    [self updateMarkers];
}


#pragma mark Carregamento do marcadores, da rota e do mapa

- (void)insertRouteOfBus:(NSString*)lineName {
    [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:lineName
                                           withCompletionHandler:^(NSArray *shapes, NSError *error) {
                                               if (!error) {
                                                   [shapes enumerateObjectsUsingBlock:^(NSMutableArray* shape, NSUInteger idxShape, BOOL *stop) {
                                                       GMSMutablePath *gmShape = [GMSMutablePath path];
                                                       [shape enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idxLocation, BOOL *stop) {
                                                           [gmShape addCoordinate:location.coordinate];
                                                       }];
                                                       GMSPolyline *polyLine = [GMSPolyline polylineWithPath:gmShape];
                                                       polyLine.strokeColor = self.lineColor[lineName];
                                                       polyLine.strokeWidth = 2.0;
                                                       polyLine.map = self.mapView;
                                                   }];
                                               } else {
                                                   NSLog(@"ERRO: Nenhuma rota para exibir");
                                               }
                                           }];
}

- (void)updateMarkers {
    [self.busesData enumerateObjectsUsingBlock:^(BusData *busData, NSUInteger idx, BOOL *stop) {
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
        marca.layer.shadowOpacity = 0.7;
        marca.layer.shadowOffset = CGSizeMake(0, 3);
        marca.layer.shadowRadius = 5.0;
        marca.layer.shadowColor = [UIColor blackColor].CGColor;
        
        self.mapBounds = [self.mapBounds includingCoordinate:marca.position];
        
    }];
    
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
    [self updateSearchedBusesData:self];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar {
    [self.searchInput becomeFirstResponder];
    [self setSuggestionsTableVisible:YES];
    [self stopCurrentRequests];
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
    self.mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate zoom:cameraCurrentLocationZoomLevel];
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
    [self stopActiveTimers];
}

- (void)appWillEnterForeground:(NSNotification *)sender {
    [self performSelector:@selector(updateSearchedBusesData:) withObject:self];
}


#pragma mark Funções utilitárias

- (void)setSuggestionsTableVisible:(BOOL)visible {
    static const float ANIMATION_DURATION = 0.2;
    
    if (visible) {
        // Appear
        [self.searchInput setShowsCancelButton:YES animated:YES];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.suggestionTable.alpha = 1.0f;
        }];
    } else {
        // Disappear
        [self.searchInput setShowsCancelButton:NO animated:YES];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.suggestionTable.alpha = 0.0f;
        }];
    }
}

@end
