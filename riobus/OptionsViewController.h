#import <UIKit/UIKit.h>

@protocol OptionsViewControllerDelegate <NSObject>
@end

@interface OptionsViewController : UIViewController

@property (weak, nonatomic) id<OptionsViewControllerDelegate> delegate;

@end
