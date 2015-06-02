#import <UIKit/UIKit.h>
IB_DESIGNABLE
@interface BusLineBarView : UIView

- (void)appear;
- (void)hide;

@property (weak, nonatomic) IBOutlet UILabel *busLineLabel;

@end
