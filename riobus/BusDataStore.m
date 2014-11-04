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
#define BUSDATA_IDX_DIRECTION       6

#define BUS_ROUTE_SHAPE_ID_INDEX            4
#define BUS_ROUTE_LATITUDE_INDEX            5
#define BUS_ROUTE_LONGITUDE_INDEX           6

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

- (NSOperation *)loadBusLineShapeForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *)) handler{
    // Previne URL injection
    AFHTTPRequestOperation *operation;
    NSString *webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary* buses = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Rotas de Onibus"] mutableCopy];
    if (!buses) buses = [[NSMutableDictionary alloc] init];
    
    NSString* csvData = [buses objectForKey:webSafeNumber];
    if (!csvData){
        NSString *strUrl = [NSString stringWithFormat:@"http://dadosabertos.rio.rj.gov.br/apiTransporte/Apresentacao/csv/gtfs/onibus/percursos/gtfs_linha%@-shapes.csv", webSafeNumber];
        
        // Monta o request
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
        operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        // Chama a URL
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSData* responseObject) {
            NSString *response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            [buses setObject:response forKey:webSafeNumber];
            [[NSUserDefaults standardUserDefaults] setObject:buses forKey:@"Rotas de Onibus"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Chama "callback" de retorno na thread principal (evita problemas na atualizacao da interface)
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil, error);
            });
        }];
        
        csvData = [buses objectForKey:webSafeNumber];
    }
    if (csvData){
        NSArray* pontosDoPercurso = [csvData componentsSeparatedByString:@"\n"];
        NSArray* dadosDoPonto = [pontosDoPercurso[1] componentsSeparatedByString:@","];
        
        // Converte dados para lista de shapes
        NSMutableArray *shapes = [[NSMutableArray alloc] initWithCapacity:6];
        NSCharacterSet* quoteCharSet = [NSCharacterSet characterSetWithCharactersInString:@"\""] ;
        [shapes addObject:[[NSMutableArray alloc] initWithCapacity:200]];
        __block NSString *lastShapeId = dadosDoPonto[BUS_ROUTE_SHAPE_ID_INDEX];
        [pontosDoPercurso enumerateObjectsUsingBlock:^(NSString *shapeItem, NSUInteger idx, BOOL *stop) {
            NSArray* dadosDoPonto = [shapeItem componentsSeparatedByString:@","];
            if ([dadosDoPonto count]>6){
                NSString *strLatitude = [dadosDoPonto[BUS_ROUTE_LATITUDE_INDEX] stringByTrimmingCharactersInSet:quoteCharSet];
                NSString *strLongitude = [dadosDoPonto[BUS_ROUTE_LONGITUDE_INDEX] stringByTrimmingCharactersInSet:quoteCharSet];
            
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[strLatitude doubleValue] longitude:[strLongitude doubleValue]];
                NSString *currShapeId = dadosDoPonto[BUS_ROUTE_SHAPE_ID_INDEX];
            
                NSMutableArray *currShapeArray ;
                if ( [lastShapeId isEqualToString:currShapeId] ) {
                    currShapeArray = [shapes lastObject];
                } else {
                    currShapeArray = [[NSMutableArray alloc] initWithCapacity:200];
                    [shapes addObject:currShapeArray];
                }
                lastShapeId = currShapeId ;
                [currShapeArray addObject:location];
            }
        }];
        
        handler(shapes, nil);
        
    }
    
    [operation start];
    return operation ;
}

- (NSOperation *)loadBusDataForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *)) handler {
    // Previne URL injection
    NSString* webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *strUrl = [NSString stringWithFormat:@"http://riob.us:81/?linha=%@&s=2", webSafeNumber];
    
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
            busData.direction = jsonBusData[BUSDATA_IDX_DIRECTION];
            
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
