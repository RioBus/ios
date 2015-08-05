#import <Foundation/Foundation.h>
#import "BusData.h"

@interface BusDataStore : NSObject

/**
 * Obtém a instância singleton de BusDataStore, inicializando-a caso necessário.
 * @returns Instância singleton de BusDataStore
 */
+ (instancetype)sharedInstance;

// TODO: documentation
- (NSOperation *)loadTrackedBusLinesWithCompletionHandler:(void (^)(NSDictionary *, NSError *))handler;

/**
 * Carrega do servidor um array com os ônibus da linha selecionada.
 * @param lineNumber Número da linha de ônibus (ex: 485).
 * @param handler Bloco a ser executado ao final da operação, que terá como entrada busesData contendo os ônibus ou um objeto nil caso nenhum seja encontrado e error que será nil caso  a operação não tenha falhas ou um objeto NSError caso ocorra algum erro.
 * @returns Retorna a operação relacionada ao request dos dados.
 */
- (NSOperation*)loadBusDataForLineNumber:(NSString*)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *))handler;

/**
 * Carrega do servidor um dicionário com as informações da linha selecionada, como seu itinerário.
 * @param lineNumber Número da linha de ônibus (ex: 485).
 * @param handler Bloco a ser executado ao final da operação, que terá como entrada um dicionário contendo as informações da linha, como nome e os pontos do percurso.
 * @returns Retorna a operação relacionada ao request dos dados.
 */
- (NSOperation*)loadBusLineItineraryForLineNumber:(NSString *)lineNumber withCompletionHandler:(void (^)(NSArray *, NSError *))handler;

@end
