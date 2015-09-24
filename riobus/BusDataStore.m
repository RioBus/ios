#import "BusDataStore.h"
#import "BusData.h"
#import <AFNetworking/AFNetworking.h>

@implementation BusDataStore

static const NSString *host = @"http://rest.riob.us";
static const float cacheVersion = 3.0;

+ (instancetype)sharedInstance {
    static id sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Check if the user's cache is in the proper version, rebuilding it otherwise
        if ([[NSUserDefaults standardUserDefaults] floatForKey:@"cache_version"] < cacheVersion) {
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"bus_itineraries"];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Rotas de Onibus"];
            [[NSUserDefaults standardUserDefaults] setFloat:cacheVersion forKey:@"cache_version"];
            NSLog(@"User's cache redefined (cache wasn't found or was too old).");
        }
    }
    return self;
}

- (NSOperation *)loadTrackedBusLinesWithCompletionHandler:(void (^)(NSDictionary *, NSError *))handler {
    AFHTTPRequestOperation *operation;
//    NSDictionary *cachedLines = [[NSUserDefaults standardUserDefaults] objectForKey:@"tracked_bus_lines"];
//    // TODO: set prescription date for cache
//    if (!cachedLines) {
//        NSLog(@"Tracked lines database not on cache.");
        NSString *strUrl = [NSString stringWithFormat:@"%@/v3/itinerary", host];
        NSLog(@"URL = %@" , strUrl);
        
        // Prepare request
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
        operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        // Fetch URL
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSData *responseObject) {
            NSError *jsonParseError;
            NSArray *availableLines = [NSJSONSerialization JSONObjectWithData:responseObject options: NSJSONReadingMutableContainers error:&jsonParseError];
            if (jsonParseError) {
                NSLog(@"Error decoding JSON itinerary data");
            }
            else {
                NSMutableDictionary *fetchedLines = [[NSMutableDictionary alloc] initWithCapacity:availableLines.count];
                for (NSDictionary *lineData in availableLines) {
                    NSString *lineName = lineData[@"line"];
                    fetchedLines[lineName] = lineData[@"description"];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:fetchedLines forKey:@"tracked_bus_lines"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RioBusDidUpdateTrackedLines" object:fetchedLines];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(fetchedLines, nil);
                });
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"ERROR: Bus lines request to server failed. %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, error);
            });
        }];
        
        [operation start];
//    }
//    else {
//        NSLog(@"Tracked bus lines found on cache.");
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            handler(cachedLines, nil);
//        });
//    }

    return operation;
}

- (NSOperation *)loadBusLineItineraryForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *))handler {
    // Avoid URL injection
    AFHTTPRequestOperation *operation;
    NSString *webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary* buses = [[[NSUserDefaults standardUserDefaults] objectForKey:@"bus_itineraries"] mutableCopy];
    if (!buses) {
        buses = [[NSMutableDictionary alloc] init];
    }
    
    // Search for cached bus line information
    __block NSString *jsonData = buses[webSafeNumber];
    if (!jsonData) {
        NSLog(@"Itinerary for line %@ is not on cache.", webSafeNumber);
        NSString *strUrl = [NSString stringWithFormat:@"%@/v3/itinerary/%@", host, webSafeNumber];
        NSLog(@"URL = %@" , strUrl);
        
        // Prepare request
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
        operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        // Fetch URL
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSData* responseObject) {
            jsonData = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            
            if (![jsonData isEqualToString:@""]) {
                buses[webSafeNumber] = jsonData;
                [[NSUserDefaults standardUserDefaults] setObject:buses forKey:@"bus_itineraries"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                NSLog(@"Itinerary for line %@ now cached.", webSafeNumber);
            }
            else {
                NSLog(@"Itinerary for line %@ returned empty.", webSafeNumber);
            }
                      
            [self processBusLineItinerary:lineNumber withJsonData:jsonData withCompletionHandler:handler];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Send data to callback on main thread to avoid issues updating the UI
            NSLog(@"ERROR: Itinerary request to server failed. %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, error);
            });
        }];
        
        [operation start];
    }
    else {
        NSLog(@"Itinerary for line %@ found on cache.", webSafeNumber);
        
        [self processBusLineItinerary:lineNumber withJsonData:jsonData withCompletionHandler:handler];
    }
    
    return operation;
}

- (void)processBusLineItinerary:(NSString *)lineNumber withJsonData:(NSString *)jsonData withCompletionHandler:(void (^)(NSArray *itinerarySpots, NSError *error))handler {
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
        NSArray *itinerarySpotsDictionaries = itinerary[@"spots"];
        NSMutableArray *itinerarySpots = [[NSMutableArray alloc] initWithCapacity:itinerarySpotsDictionaries.count];
        
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

- (NSOperation *)loadBusDataForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *))handler {
    // Prepare request
    NSString *webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *strUrl = [NSString stringWithFormat:@"%@/v3/search/%@", host, webSafeNumber];
    NSLog(@"URL = %@" , strUrl);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Fetch URL
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *jsonBusesData = (NSArray *)responseObject;
        NSMutableArray *busesData = [[NSMutableArray alloc] initWithCapacity:jsonBusesData.count];
        
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
