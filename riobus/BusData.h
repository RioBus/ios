#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BusData : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSString *)destination;
- (NSString *)humanReadableDelay;
- (NSInteger)delayInMinutes;
- (NSInteger)delayInSeconds;
+ (NSString *)humanReadableStringForSeconds:(NSInteger)value;

@property NSDate *lastUpdate;
@property NSString *order;
@property NSString *lineNumber;
@property NSNumber *velocity;
@property CLLocation *location;
@property NSNumber *direction;
@property NSString *sense;


@end
