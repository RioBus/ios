#import <Foundation/Foundation.h>
#import "BusData.h"

@interface BusDataStore : NSObject

+ (BusDataStore*)sharedInstance;

- (NSOperation*)loadBusDataForLineNumber:(NSString*)lineNumber withCompletionHandler:(void (^)(NSArray *busesData, NSError *error))handler;
- (NSOperation*)loadBusLineShapeForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *))handler;

@end
