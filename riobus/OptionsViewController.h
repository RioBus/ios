#import <UIKit/UIKit.h>

@protocol OptionsViewControllerDelegate <NSObject>
@end

@interface OptionsViewController : UIViewController<UIAlertViewDelegate>

@property (weak, nonatomic) id<OptionsViewControllerDelegate> delegate;

@end
