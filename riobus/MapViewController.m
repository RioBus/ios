#import <GoogleMaps/GoogleMaps.h>
#import <Google/Analytics.h>
#import <PSTAlertController.h>
#import <SVProgressHUD.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "MapViewController.h"
#import "BusDataStore.h"
#import "OptionsViewController.h"
#import "BusSuggestionsTable.h"
#import "BusLineBar.h"
#import "riobus-Swift.h"

@interface MapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, UISearchBarDelegate, BusLineBarDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSMutableDictionary *markerForOrder;
@property (nonatomic) NSArray *busesData;
@property (nonatomic) NSDictionary *busLineInformation;
@property (nonatomic) NSString *searchedLine;
@property (nonatomic) NSString *searchedDirection;
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) GMSCoordinateBounds *mapBounds;
@property (nonatomic) NSMutableArray *lastRequests;
@property (nonatomic, readonly, copy) NSString *favoriteLine;
@property (nonatomic, readonly) BOOL favoriteLineMode;
@property (nonatomic) CGFloat suggestionTableBottomSpacing;
@property (nonatomic) BOOL searchBarShouldBeginEditing;
@property (nonatomic) id<GAITracker> tracker;

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak, nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak, nonatomic) IBOutlet BusLineBar *busLineBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *locationMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *informationMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *arrowUpMenuButton;

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
    
    self.markerForOrder = [[NSMutableDictionary alloc] initWithCapacity:20];
    self.lastRequests = [[NSMutableArray alloc] init];
    
    self.mapView.mapType = kGMSTypeNormal;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        self.mapView.myLocationEnabled = YES;
    }
    
    self.suggestionTable.searchInput = self.searchInput;
    self.suggestionTable.alpha = 0;
    
    [self.informationMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.informationMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.favoriteMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
//    [self.favoriteMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateSelected];
    [self.favoriteMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appDarkBlueColor] forUIControlState:UIControlStateNormal];
    
    self.busLineBar.delegate = self;
    
    self.searchBarShouldBeginEditing = YES;
    self.searchInput.backgroundImage = [UIImage new];
    [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil].tintColor = [UIColor whiteColor];
    
    [SVProgressHUD setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    [SVProgressHUD setForegroundColor:[UIColor appDarkBlueColor]];
    
    self.tracker = [[GAI sharedInstance] defaultTracker];
    
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
        
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:cameraDefaultLatitude
                                                      longitude:cameraDefaultLongitude
                                                           zoom:cameraDefaultZoomLevel];
    
    [self.tracker set:kGAIScreenName value:@"Mapa"];
    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}


#pragma mark Menu actions

- (IBAction)informationMenuButtonTapped:(UIButton *)sender {
    [self performSegueWithIdentifier:@"ViewAboutScreen" sender:self];
}

- (IBAction)locationMenuButtonTapped:(UIButton *)sender {
    // Verifica se o usuário possui os Serviços de Localização habilitados no aparelho
    if ([CLLocationManager locationServicesEnabled]) {
        // Verifica se autorizou o uso da localização no app
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        switch (authorizationStatus) {
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            case kCLAuthorizationStatusAuthorized:
                [self.locationManager startUpdatingLocation];
                break;
            case kCLAuthorizationStatusNotDetermined:
            case kCLAuthorizationStatusRestricted:
                if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                    [self.locationManager requestWhenInUseAuthorization];
                }
                else {
                    [self.locationManager startUpdatingLocation];
                }
                break;
            case kCLAuthorizationStatusDenied:
                [PSTAlertController presentOkAlertWithTitle:@"Uso da localização não autorizado" andMessage:@"Você não autorizou o uso da sua localização para o RioBus. Para alterar esta configuração, vá em Ajustes > Privacidade > Serv. Localização > Rio Bus e habilite esta configuração."];
                break;
            default:
                break;
        }
    }
    else {
        [PSTAlertController presentOkAlertWithTitle:@"Serviços de localização desabilitados" andMessage:@"O uso da sua localização está desativado nas configurações do seu aparelho. Você pode ativá-lo em Ajustes > Privacidade > Serv. Localização."];
    }
}

- (IBAction)rightMenuButtonTapped:(UIButton *)sender {
    if (!self.searchedLine) {
        // Se o usuário definiu uma linha favorita
        if (self.favoriteLine) {
            [self searchForBusLine:self.favoriteLine];
            
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UI"
                                                                       action:@"Clicou menu favorito"
                                                                        label:[NSString stringWithFormat:@"Pesquisou linha favorita %@", self.favoriteLine]
                                                                        value:nil] build]];
        }
        else {
            [PSTAlertController presentOkAlertWithTitle:@"Você não possui nenhuma linha favorita" andMessage:@"Para definir uma linha favorita, pesquise uma linha e selecione a estrela ao lado dela."];
        }
    }
    else {
        [self.busLineBar appearWithBusLine:self.busLineInformation];
    }
    
}

- (IBAction)arrowMenuButtonTapped:(UIButton *)sender {
    [self.busLineBar appearWithBusLine:self.busLineInformation];
}


#pragma mark Favorite line methods

- (NSString *)favoriteLine {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"favorite_line"];
}

- (BOOL)favoriteLineMode {
    return [self.searchedLine isEqualToString:self.favoriteLine];
}

- (void)setSearchedLine:(NSString *)searchedLine {
    _searchedLine = searchedLine;
    if (searchedLine) {
        self.arrowUpMenuButton.hidden = NO;
        [self.favoriteMenuButton setTitle:searchedLine forState:UIControlStateNormal];
        [self.favoriteMenuButton setImage:nil forState:UIControlStateNormal];
    }
    else {
        self.arrowUpMenuButton.hidden = YES;
        [self.favoriteMenuButton setTitle:nil forState:UIControlStateNormal];
        [self.favoriteMenuButton setImage:[UIImage imageNamed:@"Star"] forState:UIControlStateNormal];
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
    [self.busLineBar hide];
    [self.updateTimer invalidate];
    [self cancelCurrentRequests];
    [SVProgressHUD dismiss];
    self.searchInput.text = @"";
    self.searchedLine = nil;
    self.searchedDirection = nil;
    self.busLineInformation = nil;
}

/**
 * Inicia pesquisa por uma linha de ônibus, buscando o itinerário da linha e os ônibus. Método assíncrono.
 * @param busLine Nome da linha de ônibus.
 */
- (void)searchForBusLine:(NSString * __nonnull)busLine {
    // Clear map and previous search parameters
    [self.markerForOrder removeAllObjects];
    [self.mapView clear];
    
    // Set new search parameters
    self.searchedLine = busLine;
    self.searchInput.text = busLine;
    self.searchedDirection = nil;
    [self.busLineBar selectDestination:nil];
    
    // Draw itineraries
    [self insertRouteOfBus:self.searchedLine];
    
    // Call updater
    [SVProgressHUD show];
    [self updateSearchedBusesData];
}

/**
 * Busca e insere no mapa as informações de itinerário da linha. Método assíncrono.
 * @param busLine Nome da linha de ônibus.
 */
- (void)insertRouteOfBus:(NSString * __nonnull)busLine {
    [SVProgressHUD show];
    
    [[BusDataStore sharedInstance] loadBusLineInformationForLineNumber:busLine
                                                 withCompletionHandler:^(NSDictionary *busLineInformation, NSError *error) {
                                                     [SVProgressHUD popActivity];
                                                     
                                                     self.busLineInformation = busLineInformation;
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
                                                                                                                  
                                                         [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                                                                    action:@"Erro atualizando BusData"
                                                                                                                     label:[NSString stringWithFormat:@"Itinerário indisponível (%@)", self.searchedLine]
                                                                                                                     value:nil] build]];
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
                                                                     [SVProgressHUD dismiss];
                                                                     
                                                                     if (error.code != NSURLErrorCancelled) {
                                                                         if ([AFNetworkReachabilityManager sharedManager].isReachable) {
                                                                             [PSTAlertController presentOkAlertWithTitle:@"Erro comunicando com o servidor" andMessage:@"Não foi possível buscar as posições dos ônibus. Por favor, tente novamente."];
                                                                             
                                                                             [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                                                                                        action:@"Erro atualizando BusData"
                                                                                                                                         label:@"Erro comunicando com o servidor"
                                                                                                                                         value:nil] build]];
                                                                         }
                                                                         else {
                                                                             [PSTAlertController presentOkAlertWithTitle:@"Sem conexão com a internet" andMessage:@"Não foi possível buscar as posições dos ônibus pois parece não haver conexão com a internet."];
                                                                             
                                                                             [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                                                                                        action:@"Erro atualizando BusData"
                                                                                                                                         label:@"Sem conexão com a internet"
                                                                                                                                         value:nil] build]];
                                                                         }
                                                                     }
                                                                     
                                                                     self.busesData = nil;
                                                                 }
                                                                 else {
                                                                     if (busesData.count > 0) {
                                                                         self.busesData = busesData;
                                                                         [self updateBusMarkers];
                                                                         [SVProgressHUD popActivity];
                                                                         
                                                                         self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15
                                                                                                                             target:self
                                                                                                                           selector:@selector(updateSearchedBusesData)
                                                                                                                           userInfo:nil
                                                                                                                            repeats:NO];
                                                                     }
                                                                     else {
                                                                         self.busesData = nil;
                                                                         
                                                                         [self.busLineBar hide];
                                                                         [SVProgressHUD dismiss];
                                                                         
                                                                         [PSTAlertController presentOkAlertWithTitle:[NSString stringWithFormat:@"Nenhum ônibus encontrado para a linha %@", self.searchedLine] andMessage:@"Esta linha pode não estar sendo monitorada pela Prefeitura no momento ou não existir."];
                                                                         
                                                                         [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                                                                                    action:@"Erro atualizando BusData"
                                                                                                                                     label:[NSString stringWithFormat:@"Nenhum ônibus encontrado (%@)", self.searchedLine]
                                                                                                                                     value:nil] build]];
                                                                         
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
                marker.icon = self.favoriteLineMode ? [UIImage imageNamed:@"BusMarkerFavorite"] : [UIImage imageNamed:@"BusMarker"];
                self.markerForOrder[busData.order] = marker;
                
            }
            
            marker.title = busData.destination ? [NSString stringWithFormat:@"%@ → %@", busData.order, busData.destination] : busData.order;
            marker.snippet = [NSString stringWithFormat:@"Velocidade: %.0f km/h\nAtualizado %@", busData.velocity.doubleValue, busData.humanReadableDelay];
            marker.position = busData.location.coordinate;
            if (busData.delayInMinutes >= 5) {
                marker.opacity = 0.5;
            }
        }
        // Se o ônibus for para a direção contrária e já estiver no mapa
        else if (marker) {
            marker.map = nil;
            [self.markerForOrder removeObjectForKey:busData.order];
        }
    }
}


#pragma mark UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchInput resignFirstResponder];
    [self.searchInput setShowsCancelButton:NO animated:YES];
    [self setSuggestionsTableVisible:NO];
    
    // Escape search input
    NSCharacterSet *validCharacters = [NSCharacterSet alphanumericCharacterSet];
    NSString *escapedBusLineString = [[searchBar.text.uppercaseString componentsSeparatedByCharactersInSet:[validCharacters invertedSet]] componentsJoinedByString:@""];
    
    if (![escapedBusLineString isEqualToString:@""]) {
        // Save search to history
        [self.suggestionTable addToRecentTable:escapedBusLineString];

        // Search bus line
        [self searchForBusLine:escapedBusLineString];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(![searchBar isFirstResponder]) {
        self.searchBarShouldBeginEditing = NO;
        [self clearSearch];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    BOOL boolToReturn = self.searchBarShouldBeginEditing;
    self.searchBarShouldBeginEditing = YES;
    
    if (boolToReturn) {
        [self setSuggestionsTableVisible:YES];
        [SVProgressHUD dismiss];
    }
    
    return boolToReturn;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self setSuggestionsTableVisible:NO];
    
    if (searchBar.text.length == 0) {
        [self clearSearch];
    }
}


#pragma mark CLLocationManagerDelegate methods

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    }
    return _locationManager;
}

- (void)locationManager:(nonnull CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        [PSTAlertController presentOkAlertWithTitle:@"Uso da localização não autorizado" andMessage:@"Para alterar esta configuração no futuro, vá em Ajustes > Privacidade > Serv. Localização > Rio Bus e autorize o uso da sua localização."];
        
        [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                   action:@"Usuário não atualizou localização"
                                                                    label:@""
                                                                    value:nil] build]];
        
        self.mapView.myLocationEnabled = NO;
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorized) {
        [self.locationManager startUpdatingLocation];
        self.mapView.myLocationEnabled = YES;
    }
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
        self.suggestionTable.hidden = NO;
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
