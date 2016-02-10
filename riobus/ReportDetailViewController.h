#import <UIKit/UIKit.h>

@interface ReportDetailViewController : UIViewController

@property (nonatomic) NSDictionary *problem;
@property (weak, nonatomic) IBOutlet UILabel *problemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *problemMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;

@end
