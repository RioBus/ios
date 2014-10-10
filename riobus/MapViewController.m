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

@interface MapViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, OptionsViewControllerDelegate, UISearchBarDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableDictionary *markerForOrder;
@property (strong, nonatomic) NSArray *busesData;
@property (strong, nonatomic) NSTimer *updateTimer;
@property (weak,   nonatomic) NSOperation *lastRequest;
@property (weak,   nonatomic) IBOutlet GMSMapView *mapView;
@property (weak,   nonatomic) IBOutlet UISearchBar *searchInput;
@property (weak,   nonatomic) IBOutlet UIToolbar *accessoryView;
@property (weak,   nonatomic) IBOutlet UIView *overlayMap;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.markerForOrder = [[NSMutableDictionary alloc] initWithCapacity:100];

    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locationManager startUpdatingLocation];
    
    self.mapView.mapType = kGMSTypeNormal;
    self.mapView.trafficEnabled = YES;
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

- (void)hideKeyboard:(UIButton *)sender {
    [self.searchInput resignFirstResponder];
    [sender removeFromSuperview];
    
    if (self.searchInput.text.length > 0)
        [self searchBarSearchButtonClicked:nil];
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    UIButton *overlayButton = [[UIButton alloc] initWithFrame:self.view.frame];
    overlayButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3f];
    [overlayButton addTarget:self action:@selector(hideKeyboard:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:overlayButton];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self.searchInput resignFirstResponder];
    [self.markerForOrder removeAllObjects];
    [self.mapView clear];
    
    [self.view makeToastActivity];
    
    [self atualizar:self];
}

- (void)aTime {
    if(![self.searchInput isFirstResponder])
        [self atualizar:self];
}
- (void)atualizar:(id)sender {
    [self.searchInput resignFirstResponder];
    
    if ( self.lastRequest ) {
        NSLog(@"Cancelando o request antigo %@", self.lastRequest);
        [self.lastRequest cancel];
    }
    
    if ( self.searchInput.text.length > 0 ) {
        self.lastRequest = [[BusDataStore sharedInstance] loadBusDataForLineNumber:self.searchInput.text withCompletionHandler:^(NSArray *busesData, NSError *error) {
            [self.view hideToastActivity];
            if ( error ) {
                // Mostra Toast parecido com o Android
                if ( error.code != NSURLErrorCancelled ) { // Erro ao cancelar um request
                    [self.view makeToast:[error localizedDescription]];
                }
                
                // Atualiza informacoes dos marcadores
                [self updateMarkers];
            } else {
                self.busesData = busesData ;
                
                if ( self.busesData.count == 0 ) {
                    NSString *msg = [NSString stringWithFormat:@"Nenhum resultado para a linha %@", self.searchInput.text];
                    [self.view makeToast:msg];
                } else {
                    // Ajusta o timer
                    [self.updateTimer invalidate];
                    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(aTime) userInfo:nil repeats:NO];
                }
            }
        }];
    }
}

- (void)setBusesData:(NSArray*)busesData {
    _busesData = busesData ;
    [self updateMarkers];
}
- (void)updateMarkers {
    [self.busesData enumerateObjectsUsingBlock:^(BusData *busData, NSUInteger idx, BOOL *stop) {
        NSInteger delayInformation = [busData delayInMinutes];
        
        // Busca o marcador na "cache"
        GMSMarker *marca = self.markerForOrder[busData.order];
        if ( !marca ) {
            marca = [[GMSMarker alloc] init];
            [marca setMap:self.mapView];
            [self.markerForOrder setValue:marca forKey:busData.order];
        }
        
        marca.title = [busData.lineNumber description] ;
        marca.snippet = [NSString stringWithFormat:@"Ordem: %@\nVelocidade: %.0f km/h\nAtualizado há %ld %@", busData.order,
                         [busData.velocity doubleValue], (long)delayInformation, (delayInformation == 1 ? @"minuto" : @"minutos")];
        marca.position = busData.location.coordinate ;
        
        UIImage *imagem;
        if (delayInformation > 10)
            imagem = [UIImage imageNamed:@"bus-red.png"];
        else if (delayInformation > 5)
            imagem = [UIImage imageNamed:@"bus-yellow.png"];
        else
            imagem = [UIImage imageNamed:@"bus-green.png"];
        
        marca.icon = imagem;
    }];
    
    // Atuzalia infor-window corrente
    if( self.mapView.selectedMarker ) {
        // Forca atualizacao do marcador selecionado
        GMSMarker *selectedMarker = self.mapView.selectedMarker ;
        self.mapView.selectedMarker = nil ;
        self.mapView.selectedMarker = selectedMarker ;
    }    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *location = [locations lastObject];
    self.mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate zoom:11];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [segue.identifier isEqualToString:@"viewOptions"] ) {
        OptionsViewController *optionsVC = segue.destinationViewController ;
        optionsVC.delegate = self ;
    }
}

- (void)doneOptionsView {
    // Atualiza opções do mapa
}

@end
