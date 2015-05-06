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
@property (strong, nonatomic) NSTimer *updateTimer;
@property (strong, nonatomic) NSArray *busesColors;@property (weak,   nonatomic) NSMutableArray *lastRequests;
@property (weak,   nonatomic) NSOperation *lastRequest;
@property (weak,   nonatomic) IBOutlet GMSMapView *mapView;
@property (weak,   nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak,   nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak,   nonatomic) IBOutlet UIToolbar *accessoryView;
@property (weak,   nonatomic) IBOutlet UIView *overlayMap;
@property (weak,   nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomContraint;
@property (nonatomic)         BOOL hasRepositionedMap;

@end

#define CAMERA_DEFAULT_LATITUDE                -22.9043527
#define CAMERA_DEFAULT_LONGITUDE               -43.1912805
#define CAMERA_DEFAULT_ZOOM                    12
#define CAMERA_CURRENT_LOCATION_ZOOM           14
#define CAMERA_DEFAULT_PADDING                 100.0f

@implementation MapViewController

NSInteger routeColorIndex  = 0;
NSInteger markerColorIndex = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.markerForOrder = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    self.mapView.mapType = kGMSTypeNormal;
    self.mapView.trafficEnabled = YES;
    self.mapView.myLocationEnabled = YES;
    
    self.suggestionTable.alpha = 0;
    
    [self.searchInput setImage:[UIImage imageNamed:@"info.png"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
	
    [self startLocationServices];
    
    self.busesColors = @[[UIColor colorWithRed:0.0 green:152.0/255.0 blue:211.0/255.0 alpha:1.0],
                         [UIColor orangeColor], [UIColor purpleColor], [UIColor brownColor], [UIColor cyanColor],
                         [UIColor magentaColor], [UIColor blackColor], [UIColor blueColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];

    CLLocation *location = [self.mapView myLocation];
    if (location) {
        self.mapView.camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                          longitude:location.coordinate.longitude
                                                               zoom:CAMERA_CURRENT_LOCATION_ZOOM];
    } else {
        self.mapView.camera = [GMSCameraPosition cameraWithLatitude:CAMERA_DEFAULT_LATITUDE
                                                          longitude:CAMERA_DEFAULT_LONGITUDE
                                                               zoom:CAMERA_DEFAULT_ZOOM];
    }
    
}

- (void)startLocationServices {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    // This checks for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

// Atualiza os dados para o carregamento do mapa
- (void)atualizarDados:(id)sender {
    if ([self.searchInput isFirstResponder] || !self.searchInput.text.length) {
        return;
    }
    
    routeColorIndex = -1;
    markerColorIndex = -1;
    
    [self.searchInput resignFirstResponder];
    
    // Limpar possíveis requests na fila
    if (self.lastRequests) {
        for (NSOperation* request in self.lastRequests) {
            NSLog(@"Cancelando o request antigo %@", request);
            [request cancel];
        }
    }
    [self.lastRequests removeAllObjects];
    
    NSString* validCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    NSCharacterSet* splitCharacters = [[NSCharacterSet characterSetWithCharactersInString:validCharacters] invertedSet];
    NSMutableArray* buses = [[[self.searchInput.text uppercaseString] componentsSeparatedByCharactersInSet:splitCharacters] mutableCopy];
    [buses removeObject:@""];
    
    if ([buses count]) {
        [self.suggestionTable addToRecentTable:[buses componentsJoinedByString:@", "]];
        
        for (NSString* busLineNumber in buses) {
            routeColorIndex = (routeColorIndex+1)%self.busesColors.count;
            [self insertRouteOfBus:busLineNumber withColorIndex:routeColorIndex];
            
            self.lastRequest = [[BusDataStore sharedInstance] loadBusDataForLineNumber:busLineNumber
                                                                 withCompletionHandler:^(NSArray *busesData, NSError *error) {
                                                                     [self.view hideToastActivity];
                                                                     if (error) {
                                                                         // Mostra Toast parecido com o Android
                                                                         if (error.code != NSURLErrorCancelled) // Erro ao cancelar um request
                                                                             [self.view makeToast:[error localizedDescription]];
                                                                         
                                                                         // Atualiza informacoes dos marcadores
                                                                         [self updateMarkers];
                                                                     } else {
                                                                         self.busesData = busesData;
                                                                         
                                                                         if (!self.busesData.count) {
                                                                             NSString *msg = [NSString stringWithFormat:@"Nenhum resultado para a linha %@", self.searchInput.text];
                                                                             [self.view makeToast:msg];
                                                                             self.updateTimer = nil;
                                                                         }
                                                                     }
                                                                 }];
            
            [self.lastRequests addObject:self.lastRequest];
        }
    }
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(atualizarDados:) userInfo:nil repeats:NO];
}

- (void)setBusesData:(NSArray*)busesData {
    _busesData = busesData;
    [self updateMarkers];
}


#pragma mark Carregamento do marcadores, da rota e do mapa

- (void)insertRouteOfBus:(NSString*)lineName withColorIndex:(NSInteger)colorIndex {
    self.lastRequest = [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:lineName
                                                              withCompletionHandler:^(NSArray *shapes, NSError *error) {
                                                                  if (!error) {
                                                                      [shapes enumerateObjectsUsingBlock:^(NSMutableArray* shape, NSUInteger idxShape, BOOL *stop) {
                                                                          GMSMutablePath *gmShape = [GMSMutablePath path];
                                                                          [shape enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idxLocation, BOOL *stop) {
                                                                              [gmShape addCoordinate:location.coordinate];
                                                                          }];
                                                                          GMSPolyline *polyLine = [GMSPolyline polylineWithPath:gmShape];
                                                                          polyLine.strokeColor = self.busesColors[colorIndex];
                                                                          polyLine.strokeWidth = 2.0;
                                                                          polyLine.map = self.mapView;
                                                                      }];
                                                                  }
                                                              }];
    
    [self.lastRequests addObject:self.lastRequest];
}

- (void)updateMarkers {
    __block GMSCoordinateBounds* mapBounds = [[GMSCoordinateBounds alloc] init];
    
    markerColorIndex = (markerColorIndex+1)%self.busesColors.count;
    [self.busesData enumerateObjectsUsingBlock:^(BusData *busData, NSUInteger idx, BOOL *stop) {
        NSInteger delayInformation = [busData delayInMinutes];
        
        // Busca o marcador na "cache"
        GMSMarker *marca = self.markerForOrder[busData.order];
        if (!marca) {
            marca = [[GMSMarker alloc] init];
            [marca setMap:self.mapView];
            [self.markerForOrder setValue:marca forKey:busData.order];
        }
        
        marca.snippet = [NSString stringWithFormat:@"Ordem: %@\nVelocidade: %.0f km/h\nAtualizado há %@", busData.order,
                         [busData.velocity doubleValue], [busData humanReadableDelay]];
        marca.title = busData.sense;
        marca.position = busData.location.coordinate;
        marca.icon = [UIBusIcon iconForBusLine:[busData.lineNumber description] withDelay:delayInformation
                                      andColor:self.busesColors[markerColorIndex]];
        
        mapBounds = [mapBounds includingCoordinate:marca.position];
        
    }];
    
    if (!self.hasRepositionedMap) {
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:mapBounds withPadding:CAMERA_DEFAULT_PADDING]];
        self.hasRepositionedMap = YES;
    }
}


#pragma mark UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [self.searchInput resignFirstResponder];
    [self.searchInput setShowsCancelButton:NO animated:YES];
    [self.markerForOrder removeAllObjects];
    self.searchInput.showsBookmarkButton = YES;
    [self.mapView clear];
    
    [self setSuggestionsTableVisible:NO];
    
    self.hasRepositionedMap = NO;
    
    [self.view makeToastActivity];
    
    [self atualizarDados:self];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar {
    [self.searchInput becomeFirstResponder];
    [self setSuggestionsTableVisible:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
    [self.searchInput resignFirstResponder];
    [self setSuggestionsTableVisible:NO];
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar*)searchBar {
    [self performSegueWithIdentifier:@"viewOptions" sender:self];
}


#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = [locations lastObject];
    self.mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate zoom:CAMERA_CURRENT_LOCATION_ZOOM];
}


#pragma mark Segue control

// Segue que muda para a tela de Sobre
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewOptions"]) {
        OptionsViewController *optionsVC = segue.destinationViewController;
        optionsVC.delegate = self;
    }
}


#pragma mark Listeners de notificações

// Atualiza o tamanho da tabela de acordo com o tamanho do teclado
- (void)keyboardWillShow:(NSNotification *)sender {
    CGRect keyboardFrame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardBottomContraint.constant = keyboardFrame.size.height + 5;
    [self.suggestionTable layoutIfNeeded];
}

- (void)appDidEnterBackground:(NSNotification *)sender {
    // Cancela o timer para não ficar gastando bateria no background
    if (self.updateTimer) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}

- (void)appWillEnterForeground:(NSNotification *)sender {
    [self performSelector:@selector(atualizarDados:) withObject:self];
}


#pragma mark Funções utilitárias

- (void)setSuggestionsTableVisible:(BOOL)visible {
    static const float ANIMATION_DURATION = 0.2;
    static const CGFloat BACKGROUND_ALPHA = 0.3f;
    
    if (visible) {
        // Appear
        self.searchInput.showsBookmarkButton = NO;
        [self.searchInput setShowsCancelButton:YES animated:YES];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.suggestionTable.alpha = 1.0f;
            self.mapView.alpha = BACKGROUND_ALPHA;
        }];
    } else {
        // Disappear
        self.searchInput.showsBookmarkButton = YES;
        [self.searchInput setShowsCancelButton:NO animated:YES];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            self.suggestionTable.alpha = 0.0f;
            self.mapView.alpha = 1.0f;
        }];
    }
}

@end
