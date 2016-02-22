#import <Google/Analytics.h>
#import <GoogleMaps/GMSCoordinateBounds.h>
#import <PSTAlertController/PSTAlertController.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "AboutViewController.h"
#import "BusSuggestionsTable.h"
#import "MapViewController.h"
#import "riobus-Swift.h"

@interface MapViewController () <CLLocationManagerDelegate, BusSuggestionsTableDelegate, BusLineBarDelegate>

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self updateTrackedBusLines];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.myLocationEnabled = YES;
    }
    
    self.suggestionTable.searchDelegate = self;
    self.suggestionTable.searchBar = self.searchBar;
    self.suggestionTable.searchBar.delegate = self.suggestionTable;
    self.suggestionTable.alpha = 0;
    
    [self.informationMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.informationMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.favoriteMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.favoriteMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appDarkBlueColor] forUIControlState:UIControlStateNormal];
    
    self.busLineBar.delegate = self;
    
    self.searchBar.backgroundImage = [UIImage new];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[UISearchBar.class]].tintColor = [UIColor whiteColor];
    }
    else {
        [UIBarButtonItem appearanceWhenContainedIn:UISearchBar.class, nil].tintColor = [UIColor whiteColor];
    }
    
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
    
    [self.mapView setDefaultCameraPosition];
    
    [self.tracker set:kGAIScreenName value:@"Mapa"];
    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}


#pragma mark - Menu IBActions

- (IBAction)locationMenuButtonTapped:(UIButton *)sender {
    if ([CLLocationManager locationServicesEnabled]) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        switch (authorizationStatus) {
            case kCLAuthorizationStatusAuthorizedWhenInUse:
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
                [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LOCATION_DENIED_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LOCATION_DENIED_ALERT_MESSAGE", nil)];
                break;
            default:
                break;
        }
    }
    else {
        [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LOCATION_DISABLED_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LOCATION_DISABLED_ALERT_MESSAGE", nil)];
    }
}

- (IBAction)rightMenuButtonTapped:(UIButton *)sender {
    if (!self.searchedBusLine.name) {
        NSString *favoriteLine = PreferencesStore.sharedInstance.favoriteLine;
        if (favoriteLine) {
            // Escape search input
            NSString *validCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
            NSCharacterSet *splitCharacters = [[NSCharacterSet characterSetWithCharactersInString:validCharacters] invertedSet];
            NSMutableArray *buses = [[[favoriteLine uppercaseString] componentsSeparatedByCharactersInSet:splitCharacters] mutableCopy];
            [buses removeObject:@""];
            
            [self searchForBusLine:buses];
            
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UI"
                                                                       action:@"Clicou menu favorito"
                                                                        label:[NSString stringWithFormat:@"Pesquisou linha favorita %@", favoriteLine]
                                                                        value:nil] build]];
        }
        else {
            [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"NO_FAVORITE_LINE_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"NO_FAVORITE_LINE_ALERT_MESSAGE", nil)];
        }
    }
    else {
        [self.busLineBar appearWithBusLine:self.searchedBusLine];
    }
    
}

- (IBAction)arrowMenuButtonTapped:(UIButton *)sender {
    [self.busLineBar appearWithBusLine:self.searchedBusLine];
}


#pragma mark - Favorite line methods

- (BOOL)favoriteLineMode {
    return [self.searchedBusLine.name isEqualToString:PreferencesStore.sharedInstance.favoriteLine];
}


#pragma mark - Bus Suggestions Table methods

- (void)didSearchForBuses:(NSArray<NSString *> *)buses {
    [self searchForBusLine:buses];
}

- (void)didCancelSearch {
    [self clearSearchAndMap];
}

- (void)didStartEditing {
    [SVProgressHUD dismiss];
}


#pragma mark - BusLineBar methods

- (void)busLineBarView:(BusLineBar *)sender didSelectDestinations:(NSArray *)destinations {
    if (destinations.count == 1) {
        self.searchedDirection = destinations[0];
    }
    else {
        self.searchedDirection = nil;
    }
    
    [self updateBusMarkers];
}

- (void)busLineBarView:(BusLineBar *)sender didAppear:(BOOL)visible {
    if (visible) {
        self.arrowUpMenuButton.hidden = NO;
        [self.favoriteMenuButton setTitle:self.searchedBusLine.name forState:UIControlStateNormal];
        [self.favoriteMenuButton setImage:nil forState:UIControlStateNormal];
    }
    else {
        [self.favoriteMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    }
}


#pragma mark - Loading of itinerary, bus data and map markers

- (void)clearSearchAndMap {
    [self.mapView clear];
    [self.busLineBar hide];
    [self.updateTimer invalidate];
    [SVProgressHUD dismiss];
    self.searchBar.text = @"";
    self.searchedDirection = nil;
    self.searchedBusLine = nil;
    self.hasUpdatedMapPosition = NO;
    self.arrowUpMenuButton.hidden = YES;
    [self.favoriteMenuButton setTitle:nil forState:UIControlStateNormal];
    [self.favoriteMenuButton setImage:[UIImage imageNamed:@"Star"] forState:UIControlStateNormal];
}

- (void)updateTrackedBusLines {
    [SVProgressHUD showWithStatus:@"Atualizando linhas"];
    
    [RioBusAPIClient getTrackedBusLines:^(NSDictionary<NSString *,BusLine *> * _Nullable trackedLines, NSError * _Nullable error) {
        [SVProgressHUD dismiss];
        if (error && error.code != NSURLErrorCancelled) {
            
            if (AppDelegate.isConnectedToNetwork) {
                [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_MESSAGE", nil)];
                
                [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                           action:@"Erro atualizando lista de linhas"
                                                                            label:@"Erro comunicando com o servidor"
                                                                            value:nil] build]];
            }
            else {
                [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"NO_CONNECTION_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"NO_CONNECTION_ALERT_MESSAGE", nil)];
            }
            
            return;
        }
        
        NSLog(@"Bus lines loaded. Total of %lu bus lines being tracked.", (long)trackedLines.count);
        self.trackedBusLines = trackedLines;
        PreferencesStore.sharedInstance.trackedLines = trackedLines;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RioBusDidUpdateTrackedLines" object:self];
    }];
}

/**
 * Inicia pesquisa por uma linha de ônibus, buscando o itinerário da linha e os ônibus. Método assíncrono.
 * @param busLine Nome da linha de ônibus.
 */
- (void)searchForBusLine:(NSArray * __nonnull)busLines {
    // Clear map and previous search parameters
    [self.mapView clear];
    
    NSString *busLineCute = [busLines componentsJoinedByString:@", "];
    NSString *busLine = [busLines componentsJoinedByString:@","];
    
    // Save search to history
    [self.suggestionTable addToRecentTable:busLineCute];
    
    // Set new search parameters
    self.searchBar.text = busLineCute;
    self.searchedDirection = nil;
    self.hasUpdatedMapPosition = NO;
    if (self.trackedBusLines[busLine]) {
        self.searchedBusLine = self.trackedBusLines[busLine];
    }
    else {
        self.searchedBusLine = [[BusLine alloc] initWithName:busLine andDescription:nil];
    }
    [self.busLineBar appearWithBusLine:self.searchedBusLine];
    
    // Draw itineraries
    if (busLines.count == 1) {
        [self loadAndDrawItineraryForBusLine:busLine];
    }
    
    // Call updater
    [SVProgressHUD show];
    [self updateSearchedBusesData];
}

- (void)loadAndDrawItineraryForBusLine:(NSString * __nonnull)busLine {
    [SVProgressHUD show];
    
    [RioBusAPIClient getItineraryForLine:busLine completionHandler:^(NSArray<CLLocation *> * _Nullable itinerarySpots, NSError * _Nullable error) {
        [SVProgressHUD dismiss];
        
        if (!error && itinerarySpots) {
            [self.mapView drawItineraryWithSpots:itinerarySpots];
            return;
        }
        
        [self.mapView animateToDefaultCameraPosition];
        
        [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                   action:@"Erro atualizando itinerário"
                                                                    label:[NSString stringWithFormat:@"Itinerário indisponível (%@)", self.searchedBusLine.name]
                                                                    value:nil] build]];
    }];
}

- (void)updateSearchedBusesData {
    if ([self.searchBar isFirstResponder] || !self.searchedBusLine) {
        return;
    }
    
    [self.updateTimer invalidate];
    
    [RioBusAPIClient getBusesForLine:self.searchedBusLine.name completionHandler:^(NSArray<BusData *> * _Nullable buses, NSError * _Nullable error) {
        if (error) {
            [self.busLineBar hide];
            [SVProgressHUD dismiss];
            
            if (error.code != NSURLErrorCancelled) {
                if (AppDelegate.isConnectedToNetwork) {
                    [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_MESSAGE", nil)];
                    
                    [self clearSearchAndMap];
                    
                    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                               action:@"Erro atualizando BusData"
                                                                                label:@"Erro comunicando com o servidor"
                                                                                value:nil] build]];
                }
                else {
                    [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"NO_CONNECTION_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"NO_CONNECTION_ALERT_MESSAGE", nil)];
                    
                    [self clearSearchAndMap];
                    
                    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                               action:@"Erro atualizando BusData"
                                                                                label:@"Sem conexão com a internet"
                                                                                value:nil] build]];
                }
            }
            
            self.busesData = nil;
        }
        else {
            if (buses.count > 0) {
                self.busesData = buses;
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
                
                [SVProgressHUD dismiss];
                
                [PSTAlertController presentOkAlertWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NO_BUS_FOUND_ALERT_TITLE", nil), self.searchedBusLine.name] andMessage:NSLocalizedString(@"NO_BUS_FOUND_ALERT_MESSAGE", nil)];
                
                [self clearSearchAndMap];
                
                [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                           action:@"Erro atualizando BusData"
                                                                            label:[NSString stringWithFormat:@"Nenhum ônibus encontrado (%@)", self.searchedBusLine.name]
                                                                            value:nil] build]];
                
                [self.updateTimer invalidate];
            }
        }
    }];
}

- (void)updateBusMarkers {
    // Refresh markers
    self.mapBounds = [[GMSCoordinateBounds alloc] init];
    
    for (BusData *busData in self.busesData) {
        NSString *lineDescription = self.trackedBusLines[busData.lineNumber] ? self.trackedBusLines[busData.lineNumber].lineDescription : @"";
        
        // If the bus matches the selected direction, add it to the map
        if (!self.searchedDirection || [busData.destination isEqualToString:self.searchedDirection]) {
            
            [self.mapView addOrUpdateMarkerWithBusData:busData lineDescription:lineDescription];
            
            self.mapBounds = [self.mapBounds includingCoordinate:busData.location];
        }
        // If the bus doesn't match the selected direction, remove it or ignore it
        else {
            [self.mapView removeOrIgnoreMarkerWithBusData:busData];
        }
    }
    
    // Re-center map adding the user's current location, if enabled
    if (!self.hasUpdatedMapPosition) {
        if (self.mapView.myLocation) {
            self.mapBounds = [self.mapBounds includingCoordinate:self.mapView.myLocation.coordinate];
        }
        [self.mapView animateToBounds:self.mapBounds];
        self.hasUpdatedMapPosition = YES;
    }
    
}





#pragma mark - CLLocationManager methods

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
        [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LOCATION_DENIED_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LOCATION_DENIED_ALERT_MESSAGE", nil)];
        
        [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                   action:@"Usuário não atualizou localização"
                                                                    label:@""
                                                                    value:nil] build]];
        
        self.mapView.myLocationEnabled = NO;
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
        self.mapView.myLocationEnabled = YES;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = locations.lastObject;
    
    [self.mapView animateToCoordinate:location.coordinate];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error %@", error.description);
}


#pragma mark - Notification listeners

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
    // Cancela o timer para não gastar bateria no background
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

@end