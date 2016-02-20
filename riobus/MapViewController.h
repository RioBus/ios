#import <UIKit/UIKit.h>
#import "BusData.h"
#import "BusLine.h"
#import "BusLineBar.h"
#import "riobus-Swift.h"

@interface MapViewController : UIViewController

@property (weak, nonatomic) IBOutlet MapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet BusSuggestionsTable *suggestionTable;
@property (weak, nonatomic) IBOutlet BusLineBar *busLineBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *locationMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *informationMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *arrowUpMenuButton;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) GMSCoordinateBounds *mapBounds;

@property (nonatomic) NSArray<BusData *> *busesData;
@property (nonatomic) NSDictionary *trackedBusLines;
@property (nonatomic) BusLine *searchedBusLine;
@property (nonatomic) NSString *searchedDirection;
@property (nonatomic) BOOL hasUpdatedMapPosition;

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) NSMutableArray<NSOperation *> *lastRequests;
@property (nonatomic, readonly) BOOL favoriteLineMode;
@property (nonatomic) CGFloat suggestionTableBottomSpacing;
@property (nonatomic) id<GAITracker> tracker;

@end
