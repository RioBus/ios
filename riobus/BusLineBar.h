#import <UIKit/UIKit.h>

@class BusLineBar;
@class BusLine;

@protocol BusLineBarDelegate <NSObject>

/**
 * Notifies the delegate that the user is trying to select a different destination and updates the view if successful.
 * @param sender The sender of the notification.
 * @param destination The name of the destination the user has selected.
 */
- (void)busLineBarView:(BusLineBar *)sender didSelectDestinations:(NSArray *)destinations;

/**
 * Notifies the delegate that the bus bar has finished all animations and is now visibile. Optional method.
 * @param sender The sender of the notification.
 * @param visible YES if the bar is now visible or NO if it is now hidden.
 */
@optional
- (void)busLineBarView:(BusLineBar *)sender didAppear:(BOOL)visible;

@end

@interface BusLineBar : UIView

/**
 * Make bar appear in the view sliding from the bottom of the screen with the information about the especified line.
 * @param busLine A BusLine object containing the line number, line name and destinations.
 */
- (void)appearWithBusLine:(BusLine *)busLine;

/**
 * Hide bar from the view sliding to the bottom of the screen
 */
- (void)hide;

/**
 * Array of currently selected destinations (NSStrings). Will always be of size 1 or 2.
 */
@property (nonatomic, readonly, copy) NSArray *selectedDestinations;

@property (weak, nonatomic) IBOutlet UILabel *lineNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *rightDestinationButton;
@property (weak, nonatomic) IBOutlet UIButton *leftDestinationButton;
@property id<BusLineBarDelegate> delegate;

@end
