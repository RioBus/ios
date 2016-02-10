#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <Google/Analytics.h>
#import <PSTAlertController.h>
#import <SVProgressHUD.h>
#import "BusDataStore.h"
#import "BusSuggestionsTable.h"
#import "MapViewController.h"
#import "AboutViewController.h"

@interface MapViewController () <CLLocationManagerDelegate,  UISearchBarDelegate, BusLineBarDelegate>

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lastRequests = [[NSMutableArray alloc] init];
    
    [BusDataStore updateUsersCacheIfNecessary];
    [self updateTrackedBusLines];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        self.mapView.myLocationEnabled = YES;
    }
    
    self.suggestionTable.searchBar = self.searchBar;
    self.suggestionTable.alpha = 0;
    
    [self.informationMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.informationMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.favoriteMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.favoriteMenuButton setBackgroundColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appLightBlueColor] forUIControlState:UIControlStateHighlighted];
    [self.locationMenuButton setBackgroundTintColor:[UIColor appDarkBlueColor] forUIControlState:UIControlStateNormal];
    
    self.busLineBar.delegate = self;
    
    self.searchBarShouldBeginEditing = YES;
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [UIImage new];
    [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[UISearchBar.class]].tintColor = [UIColor whiteColor];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateTrackedLines:)
                                                 name:@"RioBusDidUpdateTrackedLines"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.mapView setDefaultCameraPosition];
    
    [self.tracker set:kGAIScreenName value:@"Mapa"];
    [self.tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}


#pragma mark - Menu IBActions

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
    if (!self.searchedBusLine.line) {
        // If the user has set a favourite search
        if (self.favoriteLine) {
            // Escape search input
            NSString *validCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
            NSCharacterSet *splitCharacters = [[NSCharacterSet characterSetWithCharactersInString:validCharacters] invertedSet];
            NSMutableArray *buses = [[[self.favoriteLine uppercaseString] componentsSeparatedByCharactersInSet:splitCharacters] mutableCopy];
            [buses removeObject:@""];
            
            [self searchForBusLine:buses];
            
            [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UI"
                                                                       action:@"Clicou menu favorito"
                                                                        label:[NSString stringWithFormat:@"Pesquisou linha favorita %@", self.favoriteLine]
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

- (NSString *)favoriteLine {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"favorite_line"];
}

- (BOOL)favoriteLineMode {
    return [self.searchedBusLine.line isEqualToString:self.favoriteLine];
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
        [self.favoriteMenuButton setTitle:self.searchedBusLine.line forState:UIControlStateNormal];
        [self.favoriteMenuButton setImage:nil forState:UIControlStateNormal];
    }
    else {
        [self.favoriteMenuButton setImageTintColor:[UIColor whiteColor] forUIControlState:UIControlStateNormal];
    }
}


#pragma mark - Controller methods

/**
 * Cancelar todas as requisições pendentes
 */
- (void)cancelCurrentRequests {
    if (self.lastRequests) {
        for (NSOperation *request in self.lastRequests) {
            [request cancel];
        }
    }
    
    [self.lastRequests removeAllObjects];
}


#pragma mark - Carregamento do marcadores, da rota e do mapa

/**
 * Clear map markers and current search parameters.
 */
- (void)clearSearch {
    [self.mapView clear];
    [self.busLineBar hide];
    [self.updateTimer invalidate];
    [self cancelCurrentRequests];
    [SVProgressHUD dismiss];
    self.searchBar.text = @"";
    self.searchedDirection = nil;
    self.searchedBusLine = nil;
    self.hasUpdatedMapPosition = NO;
    self.arrowUpMenuButton.hidden = YES;
    [self.favoriteMenuButton setTitle:nil forState:UIControlStateNormal];
    [self.favoriteMenuButton setImage:[UIImage imageNamed:@"Star"] forState:UIControlStateNormal];
}

/**
 * Loads dictionary of available bus lines being tracked containing line names and descriptions.
 */
- (void)updateTrackedBusLines {
    [SVProgressHUD showWithStatus:@"Atualizando linhas"];
    
    [BusDataStore loadTrackedBusLinesWithCompletionHandler:^(NSDictionary *trackedBusLines, NSError *error) {
        [SVProgressHUD dismiss];
        if (error) {
            if (error.code != NSURLErrorCancelled) {
                if ([AFNetworkReachabilityManager sharedManager].isReachable) {
                    [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_MESSAGE", nil)];
                    
                    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                               action:@"Erro atualizando lista de linhas"
                                                                                label:@"Erro comunicando com o servidor"
                                                                                value:nil] build]];
                }
                else {
                    [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"NO_CONNECTION_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"NO_CONNECTION_ALERT_MESSAGE", nil)];
                }
            }
        }
        else {
            NSLog(@"Bus lines loaded. Total of %lu bus lines being tracked.", (long)trackedBusLines.count);
            self.trackedBusLines = trackedBusLines;
        }
    }];
}

/**
 * Notification called when the application has received new bus lines from the server.
 * @param notification Notification contaning object with new bus lines.
 */
- (void)didUpdateTrackedLines:(NSNotification *)notification {
    NSLog(@"Received notification that bus lines were updated.");
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
    self.searchedBusLine = [[BusLine alloc] initWithLine:busLine andName:self.trackedBusLines[busLine]];
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
    
    [BusDataStore loadBusLineItineraryForLineNumber:busLine withCompletionHandler:^(NSArray<CLLocation *> *itinerarySpots, NSError *error) {
        [SVProgressHUD popActivity];
        
        if (!error) {
            [self.mapView drawItineraryWithSpots:itinerarySpots];
            
            return;
        }
        
        [self.mapView animateToDefaultCameraPosition];
        
        [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                   action:@"Erro atualizando BusData"
                                                                    label:[NSString stringWithFormat:@"Itinerário indisponível (%@)", self.searchedBusLine.line]
                                                                    value:nil] build]];

    }];
}

- (void)updateSearchedBusesData {
    if ([self.searchBar isFirstResponder] || !self.searchedBusLine) {
        return;
    }
    
    [self.updateTimer invalidate];
    [self cancelCurrentRequests];
    
    // Load bus data for searched line
    NSOperation *request = [BusDataStore loadBusDataForLineNumber:self.searchedBusLine.line withCompletionHandler:^(NSArray *busesData, NSError *error) {
        if (error) {
            [self.busLineBar hide];
            [SVProgressHUD dismiss];
            
            if (error.code != NSURLErrorCancelled) {
                if ([AFNetworkReachabilityManager sharedManager].isReachable) {
                    [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"LINES_UPDATE_ERROR_ALERT_MESSAGE", nil)];
                    
                    [self clearSearch];
                    
                    [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                               action:@"Erro atualizando BusData"
                                                                                label:@"Erro comunicando com o servidor"
                                                                                value:nil] build]];
                }
                else {
                    [PSTAlertController presentOkAlertWithTitle:NSLocalizedString(@"NO_CONNECTION_ALERT_TITLE", nil) andMessage:NSLocalizedString(@"NO_CONNECTION_ALERT_MESSAGE", nil)];
                    
                    [self clearSearch];
                    
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
                
                [SVProgressHUD dismiss];
                
                [PSTAlertController presentOkAlertWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NO_BUS_FOUND_ALERT_TITLE", nil), self.searchedBusLine.line] andMessage:NSLocalizedString(@"NO_BUS_FOUND_ALERT_MESSAGE", nil)];
                
                [self clearSearch];
                
                [self.tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Erros"
                                                                           action:@"Erro atualizando BusData"
                                                                            label:[NSString stringWithFormat:@"Nenhum ônibus encontrado (%@)", self.searchedBusLine.line]
                                                                            value:nil] build]];
                
                [self.updateTimer invalidate];
            }
        }
    }];
    
    [self.lastRequests addObject:request];
}

- (void)updateBusMarkers {
    // Refresh markers
    self.mapBounds = [[GMSCoordinateBounds alloc] init];
    
    for (BusData *busData in self.busesData) {
        NSString *lineName = self.trackedBusLines[busData.lineNumber] ? self.trackedBusLines[busData.lineNumber] : @"";
        
        // If the bus matches the selected direction, add it to the map
        if (!self.searchedDirection || [busData.destination isEqualToString:self.searchedDirection]) {
            
            [self.mapView addOrUpdateMarkerWithBusData:busData lineName:lineName];
            
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


#pragma mark - UISearchBar methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self setSuggestionsTableVisible:NO];
    
    NSMutableArray *buses = [[NSMutableArray alloc] init];
    for (NSString *line in [[self.searchBar.text uppercaseString] componentsSeparatedByString:@","]) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![trimmedLine isEqualToString:@""]) {
            [buses addObject:trimmedLine];
        }
    }
    
    if (buses.count > 0) {
        [self searchForBusLine:buses];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchBar isFirstResponder]) {
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
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorized) {
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


#pragma mark - Etc.

/**
 * Mostra ou esconde com uma animação a tabela de sugestões.
 * @param visible BOOL se deve tornar a tabela visível ou não.
 */
- (void)setSuggestionsTableVisible:(BOOL)visible {
    static const float animationDuration = 0.2;
    
    if (visible) {
        // Appear
        [self.searchBar setShowsCancelButton:YES animated:YES];
        self.suggestionTable.hidden = NO;
        [self.suggestionTable setContentOffset:CGPointZero animated:NO];
        [UIView animateWithDuration:animationDuration animations:^{
            self.suggestionTable.alpha = 1.0;
        }];
    }
    else {
        // Disappear
        [self.searchBar setShowsCancelButton:NO animated:YES];
        [UIView animateWithDuration:animationDuration animations:^{
            self.suggestionTable.alpha = 0.0;
        }];
    }
}

@end
