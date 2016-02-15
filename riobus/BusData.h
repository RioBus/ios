#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BusData : NSObject

/**
 * Inicializa o dado do ônibus e suas propriedades a partir de um dicionário obtido do JSON de um request ao servidor.
 * @param dictionary Dicionário contendo as chaves retornadas por um request ao servidor do RioBus. Esse dicionário deve conter as chaves timeStamp, order, line, speec, latitude, longitude, direction e sense.
 * @returns Uma instância de BusData com as propriedades definidas.
 */
- (__nullable instancetype)initWithDictionary:(NSDictionary *__nonnull)dictionary;

/**
 * Retorna o destino do ônibus, extraído a partir do sentido no nome da linha.
 * @returns Nome do destino atual do ônibus. Se o destino não pode ser identificado, um objeto nil é retornado.
 */
@property (nonatomic, readonly, copy) NSString *__nullable destination;

@property (nonatomic) NSDate *__nonnull lastUpdate;
@property (nonatomic) NSString *__nonnull order;
@property (nonatomic) NSString *__nonnull lineNumber;
@property (nonatomic) NSNumber *__nonnull velocity;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) NSNumber *__nonnull direction;
@property (nonatomic) NSString *__nullable directionName;

@end
