#import <UIKit/UIKit.h>

@interface BusLineBarView : UIView

- (void)appear;
- (void)hide;

@property (weak, nonatomic) IBOutlet UILabel *lineNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftDestinationLabel;
@property (weak, nonatomic) IBOutlet UIButton *rightDestinationButton;
@property (weak, nonatomic) IBOutlet UIButton *leftDestinationButton;

@end
