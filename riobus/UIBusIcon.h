#import <UIKit/UIKit.h>

@interface UIBusIcon : UIImage

+ (UIImage*)iconForBusLine:(NSString*)busLine withDelay:(NSInteger)delayInformation andColor:(UIColor*)color;

@end
