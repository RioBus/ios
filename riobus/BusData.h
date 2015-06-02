#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BusData : NSObject

@property NSDate *lastUpdate;
@property NSString *order;
@property NSString *lineNumber;
@property NSNumber *velocity;
@property CLLocation *location;
@property NSNumber *direction;
@property NSString *sense;

+ (NSString*)humanReadableStringForSeconds:(NSInteger)value;
- (NSString*)humanReadableDelay;
- (NSInteger)delayInMinutes;
- (NSInteger)delayInSeconds;
- (NSString*)destination;

@end
