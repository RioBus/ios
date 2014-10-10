//
//  BusDataStore.m
//  riobus
//
//  Created by Bruno do Amaral on 05/07/2014.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "BusDataStore.h"
#import <AFNetworking/AFNetworking.h>

// Indice dos campos no array retornado pelo servidor
#define BUSDATA_IDX_HOUR            0
#define BUSDATA_IDX_ID              1
#define BUSDATA_IDX_LINE_NUMBER     2
#define BUSDATA_IDX_LATITUDE        3
#define BUSDATA_IDX_LONGITUDE       4
#define BUSDATA_IDX_VELOCITY        5

@interface BusDataStore ()
@property (strong, nonatomic) NSDateFormatter *jsonDateFormat;
@end

@implementation BusDataStore

+ (BusDataStore *)sharedInstance {
    static BusDataStore *__instance ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[BusDataStore alloc] init];
    });
    return __instance ;
}

- (NSDateFormatter *)jsonDateFormat {
    // Se jsonDateFormat não existe, é instanciado em tempo de chamada
    if (! _jsonDateFormat ) {
        _jsonDateFormat = [[NSDateFormatter alloc] init];
        [_jsonDateFormat setDateFormat: @"MM-dd-yyyy HH:mm:ss"];
    }
    
    return _jsonDateFormat ;
}

- (NSOperation *)loadBusDataForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *)) handler {
    // Previne URL injection
    NSString *webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *strUrl = [NSString stringWithFormat:@"http://riob.us/proxy.php?s=1&linha=%@", webSafeNumber];
    
    NSLog(@"URL = %@" , strUrl);
    
    // Monta o request
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Chama a URL
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Objeto com os dados...
        NSArray *jsonBusesData = [responseObject objectForKey:@"DATA"];
        
        // Monta array de retorno
        NSMutableArray *busesData = [[NSMutableArray alloc] initWithCapacity:jsonBusesData.count];
        
        [jsonBusesData enumerateObjectsUsingBlock:^(NSArray *jsonBusData, NSUInteger idx, BOOL *stop) {
            BusData *busData = [[BusData alloc] init];
            busData.lastUpdate = [self.jsonDateFormat dateFromString:jsonBusData[BUSDATA_IDX_HOUR]];
            busData.order = jsonBusData[BUSDATA_IDX_ID];
            busData.lineNumber = [jsonBusData[BUSDATA_IDX_LINE_NUMBER] description];
            busData.velocity = jsonBusData[BUSDATA_IDX_VELOCITY];
            busData.location =  [[CLLocation alloc] initWithLatitude:[jsonBusData[BUSDATA_IDX_LATITUDE] doubleValue] longitude:[jsonBusData[BUSDATA_IDX_LONGITUDE] doubleValue]];
            
            [busesData addObject:busData];
        }];
        
        // Chama "callback" de retorno na thread principal (evita problemas na atualizacao da interface)
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(busesData, nil);
        });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Chama "callback" de retorno na thread principal (evita problemas na atualizacao da interface)
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, error);
        });
    }];
    
    // 5
    [operation start];
    
    return operation;
}

@end
