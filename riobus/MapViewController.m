//
//  MapViewController.m
//  riobus
//
//  Created by Bruno do Amaral on 04/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "MapViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>
#import <AFNetworking/AFNetworking.h>
#import "BusDataStore.h"
#import <Toast/Toast+UIView.h>
#import "OptionsViewController.h"
#import "UIBusIcon.h"

@interface MapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, OptionsViewControllerDelegate, UISearchBarDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableDictionary *markerForOrder;
@property (strong, nonatomic) NSArray *busesData;
@property (strong, nonatomic) NSTimer *updateTimer;
@property (strong, nonatomic) NSArray *busesColors;
@property (weak,   nonatomic) NSMutableArray *lastRequests;
@property (weak,   nonatomic) NSOperation *lastRequest;
@property (weak,   nonatomic) IBOutlet GMSMapView *mapView;
@property (weak,   nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak,   nonatomic) IBOutlet UIToolbar *accessoryView;
@property (weak,   nonatomic) IBOutlet UIView *overlayMap;
@end

#define CAMERA_DEFAULT_LATITUDE             -22.9043527
#define CAMERA_DEFAULT_LONGITUDE            -43.1912805
#define CAMERA_DEFAULT_ZOOM                 12
#define CAMERA_CURRENT_LOCATION_ZOOM        14

#define BUS_ROUTE_SHAPE_ID_INDEX            4
#define BUS_ROUTE_LATITUDE_INDEX            5
#define BUS_ROUTE_LONGITUDE_INDEX           6

@implementation MapViewController

NSInteger routeColorIndex = 0;
NSInteger markerColorIndex = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.markerForOrder = [[NSMutableDictionary alloc] initWithCapacity:100];

    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    self.mapView.mapType = kGMSTypeNormal;
    self.mapView.trafficEnabled = YES;
    self.mapView.myLocationEnabled = YES;
    
    [self.locationManager startUpdatingLocation];
}
- (void)viewWillAppear:(BOOL)animated {
    CLLocation *location = [self.mapView myLocation];
    if (location) self.mapView.camera = [GMSCameraPosition cameraWithLatitude:location.coordinate.latitude
                                                                    longitude:location.coordinate.longitude
                                                                         zoom:CAMERA_CURRENT_LOCATION_ZOOM];
             else self.mapView.camera = [GMSCameraPosition cameraWithLatitude:CAMERA_DEFAULT_LATITUDE
                                                                    longitude:CAMERA_DEFAULT_LONGITUDE
                                                                         zoom:CAMERA_DEFAULT_ZOOM];
    self.busesColors = @[[UIColor colorWithRed:0.0 green:152.0/255.0 blue:211.0/255.0 alpha:1.0],
                         [UIColor orangeColor], [UIColor purpleColor], [UIColor brownColor], [UIColor cyanColor],
                         [UIColor magentaColor], [UIColor blackColor], [UIColor blueColor]];
}

- (CLLocationManager*)locationManager {
    // Se variável não existe, a mesma é criada no momento da chamada
    if (!_locationManager) _locationManager = [[CLLocationManager alloc] init];
    return _locationManager ;
}

- (UIViewAnimationOptions)animationOptionsWithCurve:(UIViewAnimationCurve)curve {
    switch (curve) {
        case UIViewAnimationCurveEaseInOut: return UIViewAnimationOptionCurveEaseInOut;
        case UIViewAnimationCurveEaseIn:    return UIViewAnimationOptionCurveEaseIn;
        case UIViewAnimationCurveEaseOut:   return UIViewAnimationOptionCurveEaseOut;
        case UIViewAnimationCurveLinear:    return UIViewAnimationOptionCurveLinear;
    }
    return UIViewAnimationOptionCurveEaseInOut;
}
- (void)setOverlayMapVisible:(BOOL)visible withKeyboardInfo:(NSDictionary*)info {
    // Obtém dados da animação
    UIViewAnimationCurve animationCurve = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
    animationOptions |= [self animationOptionsWithCurve:animationCurve];

    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    // Inicia a animação
    if ( visible ) {
        if ( self.overlayMap.hidden ) {
            // Mostra o overlay
            self.overlayMap.alpha = 0.0 ;
            self.overlayMap.hidden = NO ;
            
            [UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{
                self.overlayMap.alpha = 0.3 ;
            } completion:nil];
        }
    } else {
        if ( !self.overlayMap.hidden ) {
            // Esconde o overlay
            [UIView animateWithDuration:animationDuration delay:0 options:animationOptions animations:^{
                self.overlayMap.alpha = 0.0 ;
            } completion:^(BOOL finished) {
                self.overlayMap.hidden = YES ;
            }];
        }
    }
}

//Funções relacionadas ao teclado e ao mecanismo de busca
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self.searchInput resignFirstResponder];
    [self.markerForOrder removeAllObjects];
    [self.mapView clear];
    
    [self.view makeToastActivity];
    
    [self atualizar:self];
}

//Atualiza o mapa
- (void)aTime {
    if(![self.searchInput isFirstResponder])
        [self atualizar:self];
}
- (void)atualizar:(id)sender {
    routeColorIndex = -1;
    markerColorIndex = -1;
    
    [self.searchInput resignFirstResponder];
    
    if (self.lastRequests) {
        for (NSOperation* request in self.lastRequests){
            NSLog(@"Cancelando o request antigo %@", request);
            [request cancel];
        }
    }
    
    if (self.searchInput.text.length>0){
        [self.lastRequests removeAllObjects];
        NSMutableArray* buses = [[self.searchInput.text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,;."]] mutableCopy];
        [buses removeObjectIdenticalTo:@""];
        
        for (NSString* busLineNumber in buses){
            routeColorIndex = (routeColorIndex+1)%self.busesColors.count;
            [self insertRouteOfBus:busLineNumber withColorIndex:routeColorIndex];
            
            self.lastRequest = [[BusDataStore sharedInstance] loadBusDataForLineNumber:busLineNumber
                                                                 withCompletionHandler:^(NSArray *busesData, NSError *error) {
                [self.view hideToastActivity];
                if (error){
                    // Mostra Toast parecido com o Android
                    if (error.code != NSURLErrorCancelled) // Erro ao cancelar um request
                        [self.view makeToast:[error localizedDescription]];
                
                    // Atualiza informacoes dos marcadores
                    [self updateMarkers];
                } else {
                    self.busesData = busesData;
                
                    if (self.busesData.count == 0){
                        NSString *msg = [NSString stringWithFormat:@"Nenhum resultado para a linha %@", self.searchInput.text];
                        [self.view makeToast:msg];
                    } else {
                        // Ajusta o timer
                        [self.updateTimer invalidate];
                        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(aTime)
                                                                          userInfo:nil repeats:NO];
                    }
                }
            }];
            
            [self.lastRequests addObject:self.lastRequest];
        }
    }
}

//Funções para determinar a distância de um ônibus para a pessoa
- (CLLocationCoordinate2D)getCoordinateForLatitude:(NSString*)latitude andLongitude:(NSString*)longitude{
    return CLLocationCoordinate2DMake([[[latitude  substringToIndex:[latitude  length]-2] substringFromIndex:1] doubleValue],
                                      [[[longitude substringToIndex:[longitude length]-2] substringFromIndex:1] doubleValue]);
}
- (CGFloat)distanceFromObject:(CLLocationCoordinate2D)objectLocation toPerson:(CLLocationCoordinate2D)personLocation{
    CGFloat medLatitude = (objectLocation.latitude + personLocation.latitude)/2;
    CGFloat metersPerLatitude = 111132.954 - 559.822*cos(2*medLatitude) + 1.175*cos(4*medLatitude);
    CGFloat metersPerLongitude = 111319.490*cos(medLatitude);
    
    CGFloat busYDist = (objectLocation.latitude - personLocation.latitude)*metersPerLatitude;
    CGFloat busXDist = (objectLocation.longitude - personLocation.longitude)*metersPerLongitude;
    
    return sqrt(busYDist*busYDist + busXDist*busXDist);
}
- (CGFloat)timeFromObject:(CLLocationCoordinate2D)objectLocation toPerson:(CLLocationCoordinate2D)personLocation atSpeed:(CGFloat)speed{
    return [self distanceFromObject:objectLocation toPerson:personLocation]/(speed/3.6);
}

//Função referentes ao carregamento do mapa
- (void)setBusesData:(NSArray*)busesData {
    _busesData = busesData ;
    [self updateMarkers];
}
- (void)insertRouteOfBus:(NSString*)lineName withColorIndex:(NSInteger)colorIndex{
    self.lastRequest = [[BusDataStore sharedInstance] loadBusLineShapeForLineNumber:lineName
                                                              withCompletionHandler:^(NSArray *shapes, NSError *error) {
        if (!error) {
            [shapes enumerateObjectsUsingBlock:^(NSMutableArray* shape, NSUInteger idxShape, BOOL *stop) {
                GMSMutablePath *gmShape = [GMSMutablePath path];
                [shape enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idxLocation, BOOL *stop) {
                    [gmShape addCoordinate:location.coordinate];
                }];
                GMSPolyline *polyLine = [GMSPolyline polylineWithPath:gmShape] ;
                polyLine.strokeColor = self.busesColors[colorIndex];
                polyLine.strokeWidth = 2.0;
                polyLine.map = self.mapView;
            }];
        }
    }];
}
- (void)updateMarkers{
    markerColorIndex = (markerColorIndex+1)%self.busesColors.count;
    [self.busesData enumerateObjectsUsingBlock:^(BusData *busData, NSUInteger idx, BOOL *stop) {
        NSInteger delayInformation = [busData delayInMinutes];
        
        // Busca o marcador na "cache"
        GMSMarker *marca = self.markerForOrder[busData.order];
        if (!marca){
            marca = [[GMSMarker alloc] init];
            [marca setMap:self.mapView];
            [self.markerForOrder setValue:marca forKey:busData.order];
        }
        
        marca.snippet = [NSString stringWithFormat:@"Ordem: %@\nVelocidade: %.0f km/h\nAtualizado há %@", busData.order,
                             [busData.velocity doubleValue], [busData humanReadableDelay]];
        marca.title = [busData.lineNumber description];
        marca.position = busData.location.coordinate;
        marca.icon = [UIBusIcon iconForBusLine:[busData.lineNumber description] withDelay:delayInformation
                                      andColor:self.busesColors[markerColorIndex]];
        
        /*
        if ([self timeFromObject:marca.position toPerson:[self.mapView myLocation].coordinate atSpeed:[busData.velocity doubleValue]] < 300.0){
            //Ação a ser tomada se ônibus estiver próximo a uma duração em segundos menor que a determinada
            //O raio precisa ser avaliado e decidido
            //Esse trecho do código está comentado por que o sistema de notificação ainda não está presente
        }
        */
    }];
    
    // Atualizar info-window corrente
    if(self.mapView.selectedMarker){
        // Forca atualizacao do marcador selecionado
        GMSMarker *selectedMarker = self.mapView.selectedMarker;
        self.mapView.selectedMarker = nil;
        self.mapView.selectedMarker = selectedMarker;
    }    
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = [locations lastObject];
    self.mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate zoom:11];
}

//Segue que muda para a tela de Sobre
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [segue.identifier isEqualToString:@"viewOptions"] ) {
        OptionsViewController *optionsVC = segue.destinationViewController ;
        optionsVC.delegate = self ;
    }
}

@end
