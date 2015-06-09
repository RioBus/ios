#import <Foundation/Foundation.h>
#import "BusData.h"

@interface BusDataStore : NSObject

+ (instancetype)sharedInstance;

- (NSOperation*)loadBusDataForLineNumber:(NSString*)lineNumber withCompletionHandler:(void (^)(NSArray *busesData, NSError *error))handler;
- (NSOperation*)loadBusLineInformationForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSDictionary *, NSError *))handler;

@end
