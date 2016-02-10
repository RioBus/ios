#import <Foundation/Foundation.h>
#import "BusData.h"

@interface BusDataStore : NSObject

+ (void)updateUsersCacheIfNecessary;

/**
 * Loads document from server containing list of all bus lines with tracking available.
 * @param handler Block to be called when operation is finished, containing a dictionary with
 * the description for each bus line. This object can be nil when an error occurs, in which case
 * the second parameter will contain an associated NSError.
 * @returns NSOperation object of the request.
 */
+ (NSOperation *)loadTrackedBusLinesWithCompletionHandler:(void (^)(NSDictionary *, NSError *))handler;

/**
 * Loads an array from the server containing all the tracked buses for the selected line.
 * @param lineNumber Line number to be tracked (e.g.: 485).
 * @param handler Block to be called when operation is finished, containing an array with all buses
 * of the specified line. This object can be nil when an error occurs, in which case the second
 * parameter will contain an associated NSError.
 * @returns NSOperation object of the request.
 */
+ (NSOperation *)loadBusDataForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray<BusData *> *, NSError *))handler;

/**
 * Loads an array from the server containing all the location points of a bus line itinerary.
 * @param lineNumber Line number to be tracked (e.g.: 485).
 * @param handler Block to be called when operation is finished, containing an array with all spots
 * of the specified line's itinerary. This object can be nil when an error occurs, in which case the 
 * second parameter will contain an associated NSError.
 * @returns NSOperation object of the request.
 */
+ (NSOperation *)loadBusLineItineraryForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray<CLLocation *> *, NSError *))handler;

@end
