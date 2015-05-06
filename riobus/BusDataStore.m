#import "BusDataStore.h"
#import <AFNetworking/AFNetworking.h>

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

- (id)init {
    self = [super init];
    if (self) {
        // Verifica se o cache salvo é incompatível com o formato atual. Isso serve caso o usuário atualize o app
        // para uma versão que usa um cache diferente.
        if ([[NSUserDefaults standardUserDefaults] floatForKey:@"cache_version"] < 2.0) {
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Rotas de Onibus"];
            [[NSUserDefaults standardUserDefaults] setFloat:2.0 forKey:@"cache_version"];
            NSLog(@"Cache do usuário redefinido (cache incompatível ou não existente).");
        }
    }
    return self;
}

- (NSDateFormatter *)jsonDateFormat {
    // Se jsonDateFormat não existe, é instanciado em tempo de chamada
    if (! _jsonDateFormat ) {
        _jsonDateFormat = [[NSDateFormatter alloc] init];
        [_jsonDateFormat setDateFormat: @"MM-dd-yyyy HH:mm:ss"];
    }
    
    return _jsonDateFormat ;
}

- (NSOperation *)loadBusLineShapeForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *)) handler {
    // Previne URL injection
    AFHTTPRequestOperation *operation;
    NSString *webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary* buses = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Rotas de Onibus"] mutableCopy];
    if (!buses) buses = [[NSMutableDictionary alloc] init];
    
    // Procura o cache da linha pesquisada
    NSString* jsonData = [buses objectForKey:webSafeNumber];
    if (!jsonData) {
        NSString *strUrl = [NSString stringWithFormat:@"http://rest.riob.us/itinerary/%@", webSafeNumber];
        NSLog(@"URL = %@" , strUrl);
        
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
        
        jsonData = [buses objectForKey:webSafeNumber];
    }
    
    if (jsonData) {
        // Agora já temos os dados da linha no cache
        NSData* itineraryJsonData = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
        NSError* jsonParseError = nil;
        NSArray* pontosDoPercurso = [NSJSONSerialization JSONObjectWithData:itineraryJsonData options: NSJSONReadingMutableContainers error:&jsonParseError];
        if (jsonParseError) {
            NSLog(@"Error decoding JSON itinerary data");
        }
        
        // Converte dados para lista de shapes
        NSMutableArray *shapes = [[NSMutableArray alloc] initWithCapacity:6];
        
        if (pontosDoPercurso.count > 0) {
            NSCharacterSet* quoteCharSet = [NSCharacterSet characterSetWithCharactersInString:@"\""] ;
            [shapes addObject:[[NSMutableArray alloc] initWithCapacity:200]];
            __block NSString *lastShapeId = pontosDoPercurso[0][@"shape"];
            
            [pontosDoPercurso enumerateObjectsUsingBlock:^(NSDictionary *dadosDoPonto, NSUInteger idx, BOOL *stop) {
                NSString *strLatitude = [dadosDoPonto[@"latitude"] stringByTrimmingCharactersInSet:quoteCharSet];
                NSString *strLongitude = [dadosDoPonto[@"longitude"] stringByTrimmingCharactersInSet:quoteCharSet];
                
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[strLatitude doubleValue] longitude:[strLongitude doubleValue]];
                NSString *currShapeId = dadosDoPonto[@"shape"];
                
                NSMutableArray *currShapeArray;
                if ([lastShapeId isEqualToString:currShapeId]) {
                    currShapeArray = [shapes lastObject];
                } else {
                    currShapeArray = [[NSMutableArray alloc] initWithCapacity:200];
                    [shapes addObject:currShapeArray];
                }
                
                lastShapeId = currShapeId;
                [currShapeArray addObject:location];
            }];
        }
        
        handler(shapes, nil);
    }
    
    [operation start];
    return operation ;
    
}

- (NSOperation *)loadBusDataForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *)) handler {
    // Previne URL injection
    NSString* webSafeNumber = [lineNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *strUrl = [NSString stringWithFormat:@"http://rest.riob.us/search/2/%@", webSafeNumber];
    NSLog(@"URL = %@" , strUrl);
    
    // Monta o request
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Chama a URL
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Objeto com os
        NSArray *jsonBusesData = (NSArray *)responseObject;
        NSMutableArray *busesData = [[NSMutableArray alloc] initWithCapacity:jsonBusesData.count];
        
        [jsonBusesData enumerateObjectsUsingBlock:^(NSDictionary *jsonBusData, NSUInteger idx, BOOL *stop) {
            BusData *bus = [[BusData alloc] init];
            bus.lastUpdate = [self.jsonDateFormat dateFromString:jsonBusData[@"timeStamp"]];
            bus.order = jsonBusData[@"order"];
            bus.lineNumber = jsonBusData[@"line"];
            bus.velocity = jsonBusData[@"speed"];
            bus.location = [[CLLocation alloc] initWithLatitude:[jsonBusData[@"latitude"] doubleValue] longitude:[jsonBusData[@"longitude"] doubleValue]];
            bus.direction = jsonBusData[@"direction"];
            bus.sense = jsonBusData[@"sense"];
            
            [busesData addObject:bus];
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
    
    [operation start];
    
    return operation;
}

@end
