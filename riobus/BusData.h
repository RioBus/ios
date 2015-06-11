#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BusData : NSObject

/**
 * Inicializa o dado do ônibus e suas propriedades a partir de um dicionário obtido do JSON de um request ao servidor.
 * @param dictionary Dicionário contendo as chaves retornadas por um request ao servidor do RioBus. Esse dicionário deve conter as chaves timeStamp, order, line, speec, latitude, longitude, direction e sense.
 * @returns Uma instância de BusData com as propriedades definidas.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 * Retorna o destino do ônibus, extraído a partir do sentido no nome da linha.
 * @returns Nome do destino atual do ônibus. Se o destino não pode ser identificado, um objeto nil é retornado.
 */
@property (nonatomic, readonly, copy) NSString *destination;

/**
 * Retorna o tempo desde o último o update em dias, horas, minutos ou segundos.
 * @returns Tempo desde o último update relativo à hora atual.
 */
@property (nonatomic, readonly, copy) NSString *humanReadableDelay;

/**
 * Retorna o tempo desde o último o update.
 * @returns Quantos minutos se passaram desde o último update do ônibus.
 */
@property (nonatomic, readonly) NSInteger delayInMinutes;

/**
 * Retorna o tempo desde o último o update.
 * @returns Quantos segundos se passaram desde o último update do ônibus.
 */
@property (nonatomic, readonly) NSInteger delayInSeconds;

/**
 * Retorna o tempo desde um número de segundos em dias, horas, minutos ou segundos.
 * @param seconds Número de segundos que se passaram.
 * @returns Tempo desde o último update relativo à hora atual.
 */
+ (NSString *)humanReadableStringForSeconds:(NSInteger)seconds;

@property (nonatomic) NSDate *lastUpdate;
@property (nonatomic) NSString *order;
@property (nonatomic) NSString *lineNumber;
@property (nonatomic) NSNumber *velocity;
@property (nonatomic) CLLocation *location;
@property (nonatomic) NSNumber *direction;
@property (nonatomic) NSString *sense;

@end
