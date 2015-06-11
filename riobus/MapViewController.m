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
@property (nonatomic) NSString *searchedLine;
@property (nonatomic) NSString *searchedDirection;
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) GMSCoordinateBounds *mapBounds;
@property (nonatomic) NSMutableArray *lastRequests;
@property (nonatomic) BOOL favoriteLineMode;
@property (nonatomic) CGFloat suggestionTableBottomSpacing;

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak, nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak, nonatomic) IBOutlet BusLineBar *busLineBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *locationMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *informationMenuButton;

@end

static const CGFloat cameraDefaultLatitude = -22.9043527;
static const CGFloat cameraDefaultLongitude = -43.1912805;
static const CGFloat cameraDefaultZoomLevel = 12.0;
static const CGFloat cameraCurrentLocationZoomLevel = 14.0;
static const CGFloat cameraPaddingTop = 50.0;
static const CGFloat cameraPaddingLeft = 30.0;
static const CGFloat cameraPaddingBottom = 100.0;
static const CGFloat cameraPaddingRight = 30.0;

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.markerForOrder = [[NSMutableDictionary alloc] initWithCapacity:100];
    self.lastRequests = [[NSMutableArray alloc] init];
    
    self.mapView.mapType = kGMSTypeNormal;
    self.mapView.myLocationEnabled = YES;
    
    self.suggestionTable.searchInput = self.searchInput;
    self.suggestionTable.alpha = 0;
    
    [self.informationMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.favoriteMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.favoriteMenuButton setImageTintColor:[UIColor appGoldColor] forUIControlState:UIControlStateSelected];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appDarkBlueColor] forUIControlState:UIControlStateNormal];
    
    self.busLineBar.delegate = self;
    
    self.searchInput.backgroundImage = [UIImage new];
    [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil].tintColor = [UIColor whiteColor];
    
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


#pragma mark Menu actions

- (IBAction)informationMenuButtonTapped:(UIButton *)sender {
    [self performSegueWithIdentifier:@"viewOptions" sender:self];
}

- (IBAction)locationMenuButtonTapped:(UIButton *)sender {
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationManager startUpdatingLocation];
    }
    else {
        NSLog(@"Location services not enabled");
    }
}

- (IBAction)favoriteMenuButtonTapped:(UIButton *)sender {
    self.favoriteLineMode = !self.favoriteLineMode;
    sender.selected = self.favoriteLineMode;
    
    if (self.favoriteLineMode) {
        [self searchForBusLine:@"324"]; // FIXME: Buscar linha favorita da memória
    }
    else {
        [self clearSearch];
    }
}


#pragma mark BusLineBarViewDelegate methods

- (BOOL)busLineBarView:(BusLineBar *)sender didSelectDestination:(NSString *)destination {
    self.searchedDirection = destination;
    [self updateBusMarkers];
    
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


#pragma mark Carregamento do marcadores, da rota e do mapa

/**
 * Limpar marcadores do mapa e últimos parâmetros de pesquisa.
 */
- (void)clearSearch {
    // Clear map and previous search parameters
    [self.markerForOrder removeAllObjects];
    [self.mapView clear];
    [self.updateTimer invalidate];
    [self cancelCurrentRequests];
    self.searchInput.text = @"";
    self.searchedLine = nil;
    self.searchedDirection = nil;
}

/**
 * Inicia pesquisa por uma linha de ônibus, buscando o itinerário da linha e os ônibus. Método assíncrono.
 * @param busLine Nome da linha de ônibus.
 */
- (void)searchForBusLine:(NSString * __nonnull)busLine {
    // Show activity indicator
    [self.view makeToastActivity];
    
    // Clear map and previous search parameters
    [self.markerForOrder removeAllObjects];
    [self.mapView clear];
    
    // Set new search parameters
    self.searchedLine = busLine;
    self.searchInput.text = busLine;
    self.searchedDirection = nil; // TODO: self.searchDirection = última direção pesquisada na linha
    
    // Draw itineraries
    [self insertRouteOfBus:self.searchedLine];
    
    // Call updater
    [self updateSearchedBusesData];
}

/**
 * Busca e insere no mapa as informações de itinerário da linha. Método assíncrono.
 * @param busLine Nome da linha de ônibus.
 */
- (void)insertRouteOfBus:(NSString * __nonnull)busLine {
    [[BusDataStore sharedInstance] loadBusLineInformationForLineNumber:busLine
                                                 withCompletionHandler:^(NSDictionary *busLineInformation, NSError *error) {
                                                     NSArray *shapes = busLineInformation[@"shapes"];
                                                     [self.busLineBar appearWithBusLine:busLineInformation];
                                                     
                                                     if (!error && shapes.count > 0) {
                                                         self.mapBounds = [[GMSCoordinateBounds alloc] init];
                                                         
                                                         NSArray *shapes = busLineInformation[@"shapes"];
                                                         for (NSMutableArray *shape in shapes) {
                                                             GMSMutablePath *gmShape = [GMSMutablePath path];
                                                             
                                                             for (CLLocation *location in shape) {
                                                                 [gmShape addCoordinate:location.coordinate];
                                                                 self.mapBounds = [self.mapBounds includingCoordinate:location.coordinate];
                                                             }
                                                             
                                                             GMSPolyline *polyLine = [GMSPolyline polylineWithPath:gmShape];
                                                             polyLine.strokeColor = [UIColor appOrangeColor];
                                                             polyLine.strokeWidth = 2.0;
                                                             polyLine.map = self.mapView;
                                                         }
                                                         
                                                         // Realinhar mapa
                                                         UIEdgeInsets mapBoundsInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.searchInput.frame) + cameraPaddingTop,
                                                                                                         cameraPaddingRight,
                                                                                                         cameraPaddingBottom,
                                                                                                         cameraPaddingLeft);
                                                         [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:self.mapBounds withEdgeInsets:mapBoundsInsets]];
                                                     }
                                                     else {
                                                         self.busLineInformation = nil;
                                                         
                                                         [self.mapView animateToCameraPosition: [GMSCameraPosition cameraWithLatitude:cameraDefaultLatitude
                                                                                                                            longitude:cameraDefaultLongitude
                                                                                                                                 zoom:cameraDefaultZoomLevel]];
                                                         
                                                         NSLog(@"ERRO: Nenhuma rota para exibir");
                                                     }
                                                 }];
}

/**
 * Atualiza os dados dos ônibus para o carregamento do mapa. Método assíncrono.
 */
- (void)updateSearchedBusesData {
    if ([self.searchInput isFirstResponder] || !self.searchedLine) {
        return;
    }
    
    [self.updateTimer invalidate];
    [self cancelCurrentRequests];
    
    // Load bus data for searched line
    NSOperation *request = [[BusDataStore sharedInstance] loadBusDataForLineNumber:self.searchedLine
                                                             withCompletionHandler:^(NSArray *busesData, NSError *error) {
                                                                 if (error) {
                                                                     [self.busLineBar hide];
                                                                     [self.view hideToastActivity];
                                                                     
                                                                     if (error.code != NSURLErrorCancelled) {                                                                         PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Erro" message:@"Não foi possível buscar a posição dos ônibus."];
                                                                         [alertController addAction:[PSTAlertAction actionWithTitle:@"OK" style:PSTAlertActionStyleDefault handler:nil]];
                                                                         [alertController showWithSender:self controller:self animated:YES completion:nil];
                                                                     }
                                                                     
                                                                     self.busesData = nil;
                                                                 }
                                                                 else {
                                                                     if (busesData.count > 0) {
                                                                         self.busesData = busesData;
                                                                         [self updateBusMarkers];
                                                                         
                                                                         self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15
                                                                                                                             target:self
                                                                                                                           selector:@selector(updateSearchedBusesData)
                                                                                                                           userInfo:nil
                                                                                                                            repeats:NO];
                                                                     }
                                                                     else {
                                                                         self.busesData = nil;
                                                                         
                                                                         [self.busLineBar hide];
                                                                         [self.view hideToastActivity];
                                                                         
                                                                         PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Erro" message:[NSString stringWithFormat:@"Nenhum ônibus encontrado para a linha %@. ", self.searchedLine]];
                                                                         [alertController addAction:[PSTAlertAction actionWithTitle:@"Ok" style:PSTAlertActionStyleDefault handler:nil]];
                                                                         [alertController showWithSender:self controller:self animated:YES completion:nil];
                                                                         
                                                                         [self.updateTimer invalidate];
                                                                     }
                                                                 }
                                                             }];
    
    [self.lastRequests addObject:request];
}

/**
 * Atualiza os marcadores dos ônibus no mapa de acordo com últimos dados e última direção.
 */
- (void)updateBusMarkers {
    // Atualizar marcadores
    for (BusData *busData in self.busesData) {
        // Busca o marcador no mapa se já existir
        GMSMarker *marker = self.markerForOrder[busData.order];
        
        // Se o ônibus for para a direção desejada, adicioná-lo no mapa
        if (!self.searchedDirection || [busData.destination isEqualToString:self.searchedDirection]) {
            if (!marker) {
                marker = [[GMSMarker alloc] init];
                marker.map = self.mapView;
                marker.icon = [UIImage imageNamed:@"BusMarker"];
                self.markerForOrder[busData.order] = marker;
            }
            
            marker.snippet = [NSString stringWithFormat:@"Ordem: %@\nVelocidade: %.0f km/h\nAtualizado há %@", busData.order, busData.velocity.doubleValue, busData.humanReadableDelay];
            marker.title = busData.sense;
            marker.position = busData.location.coordinate;
        }
        // Se o ônibus for para a direção contrária e já estiver no mapa
        else if (marker) {
            marker.map = nil;
            [self.markerForOrder removeObjectForKey:busData.order];
        }
    }
    
    [self.view hideToastActivity];
}


#pragma mark UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchInput resignFirstResponder];
    [self.searchInput setShowsCancelButton:NO animated:YES];
    [self setSuggestionsTableVisible:NO];
    
    // Escape search input
    NSCharacterSet *validCharacters = [NSCharacterSet alphanumericCharacterSet];
    NSString *escapedBusLineString = [[searchBar.text.uppercaseString componentsSeparatedByCharactersInSet:[validCharacters invertedSet]] componentsJoinedByString:@""];
    
    // Save search to history
    [self.suggestionTable addToRecentTable:escapedBusLineString];

    // Search bus line
    [self searchForBusLine:escapedBusLineString];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchInput becomeFirstResponder];
    [self setSuggestionsTableVisible:YES];
    [self cancelCurrentRequests];
    [self.view hideToastActivity];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchInput resignFirstResponder];
    [self setSuggestionsTableVisible:NO];
}


#pragma mark CLLocationManagerDelegate methods

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
 * Método chamado quando o teclado será exibido na tela. Atualiza o tamanho da 
 * tabela de acordo com o tamanho do teclado.
 * @param sender Notificação que ativou o método.
 */
- (void)keyboardWillShow:(NSNotification *)sender {
    CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.suggestionTableBottomSpacing = self.keyboardBottomConstraint.constant;
    self.keyboardBottomConstraint.constant = keyboardFrame.size.height;
    [self.suggestionTable layoutIfNeeded];
}

/**
 * Método chamado quando o teclado será escondido na tela. Atualiza o tamanho da
 * tabela de acordo com o tamanho do teclado.
 * @param sender Notificação que ativou o método.
 */
- (void)keyboardWillHide:(NSNotification *)sender {
    self.keyboardBottomConstraint.constant = self.suggestionTableBottomSpacing;
    [self.suggestionTable layoutIfNeeded];
}

/**
 * Método chamado quando o aplicativo entra em segundo plano. Cancela a atualização
 * dos dados para economizar bateria quando no background.
 * @param sender Notificação que ativou o método.
 */
- (void)appDidEnterBackground:(NSNotification *)sender {
    // Cancela o timer para não ficar gastando bateria no background
    [self.updateTimer invalidate];
}

/**
 * Método chamado quando o aplicativo entra volta para primeiro plano. Reativa a 
 * atualização dos ônibus caso tenha sido interrompida.
 * @param sender Notificação que ativou o método.
 */
- (void)appWillEnterForeground:(NSNotification *)sender {
    [self performSelector:@selector(updateSearchedBusesData)];
}


#pragma mark Funções utilitárias

/**
 * Mostra ou esconde com uma animação a tabela de sugestões.
 * @param visible BOOL se deve tornar a tabela visível ou não.
 */
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
