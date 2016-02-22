#import <AFNetworking/AFNetworking.h>
#import "BusDataStore.h"

@implementation BusDataStore

static const NSString *host = @"http://rest.riob.us";
static const float cacheVersion = 3.0;

+ (void)updateUsersCacheIfNecessary {
    if ([[NSUserDefaults standardUserDefaults] floatForKey:@"cache_version"] < cacheVersion) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"bus_itineraries"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Rotas de Onibus"];
        [[NSUserDefaults standardUserDefaults] setFloat:cacheVersion forKey:@"cache_version"];
        NSLog(@"User's cache redefined (cache wasn't found or was outdated).");
    }
}

+ (void)processBusLineItinerary:(NSString *)lineNumber withJsonData:(NSString *)jsonData withCompletionHandler:(void (^)(NSArray<CLLocation *> *itinerarySpots, NSError *error))handler {
    if (jsonData) {
        NSData *itineraryJsonData = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonParseError = nil;
        NSDictionary *itinerary = [NSJSONSerialization JSONObjectWithData:itineraryJsonData options: NSJSONReadingMutableContainers error:&jsonParseError];
        if (jsonParseError) {
            NSLog(@"Error decoding JSON itinerary data");
            // Send data to callback on main thread to avoid issues updating the UI
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, jsonParseError);
            });
            
            return;
        }
        
        // Convert JSON location data to CLLocation objects
        NSArray<NSDictionary *> *itinerarySpotsDictionaries = itinerary[@"spots"];
        NSMutableArray<CLLocation *> *itinerarySpots = [[NSMutableArray alloc] initWithCapacity:itinerarySpotsDictionaries.count];
        
        if (itinerarySpotsDictionaries.count > 0) {
            for (NSDictionary *spot in itinerarySpotsDictionaries) {
                NSString *strLatitude = spot[@"latitude"];
                NSString *strLongitude = spot[@"longitude"];
                
                CLLocation *location = [[CLLocation alloc] initWithLatitude:strLatitude.doubleValue longitude:strLongitude.doubleValue];
                [itinerarySpots addObject:location];
            }
        }
        
        // Send data to callback on main thread to avoid issues updating the UI
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(itinerarySpots, nil);
        });
    }
    
}

+ (NSOperation *)loadBusDataForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray<BusData *> *, NSError *))handler {
    // Prepare request
    NSString *webSafeNumber = [lineNumber stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *strUrl = [NSString stringWithFormat:@"%@/v3/search/%@", host, webSafeNumber];
    NSLog(@"URL = %@" , strUrl);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Fetch URL
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray<NSDictionary *> *jsonBusesData = (NSArray *)responseObject;
        NSMutableArray<BusData *> *busesData = [[NSMutableArray alloc] initWithCapacity:jsonBusesData.count];
        
        for (NSDictionary *jsonBusData in jsonBusesData) {
            BusData *bus = [[BusData alloc] initWithDictionary:jsonBusData];
            [busesData addObject:bus];
        }
        
        // Send data to callback on main thread to avoid issues updating the UI
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(busesData, nil);
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Send data to callback on main thread to avoid issues updating the UI
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, error);
        });
    }];
    
    [operation start];
    
    return operation;
}

@end
