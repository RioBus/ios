#import "BusData.h"

#define SECONDS_IN_MINUTE 60
#define MINUTES_IN_HOUR   60
#define HOUR_IN_DAY       24

@implementation BusData

- (NSString *)destination {
    // Verifica se a linha possui informação de sentido
    if (![self.sense isEqualToString:@""] && ![self.sense isEqualToString:@"desconhecido"]) {
        // Tirar informação entre parênteses do nome da linha
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\(.*\\)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *lineNameWithoutParentheses = [regex stringByReplacingMatchesInString:self.sense options:0 range:NSMakeRange(0, [self.sense length]) withTemplate:@""];
        lineNameWithoutParentheses = [lineNameWithoutParentheses stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSArray *places = [lineNameWithoutParentheses componentsSeparatedByString:@" X "];
        if ([places count] == 2) {
            return places[1];
        }
    }
    
    return nil;
}

+ (NSString*)humanReadableStringForTime:(NSInteger)value ofType:(NSString*)type {
    return [NSString stringWithFormat:@"%ld %@", (long)value,(value == 1 ? type : [type stringByAppendingString:@"s"])];
}

+ (NSString*)humanReadableStringForSeconds:(NSInteger)value {
    if (value < SECONDS_IN_MINUTE)
        return [BusData humanReadableStringForTime:value ofType:@"segundo"];
    
    value /= SECONDS_IN_MINUTE;
    if (value < MINUTES_IN_HOUR)
        return [BusData humanReadableStringForTime:value ofType:@"minuto"];
    
    value /= MINUTES_IN_HOUR;
    if (value < HOUR_IN_DAY)
        return [BusData humanReadableStringForTime:value ofType:@"hora"];
    
    value /= HOUR_IN_DAY;
    return [BusData humanReadableStringForTime:value ofType:@"dia"];
}

- (NSString*)humanReadableDelay {
    return [BusData humanReadableStringForSeconds:[self delayInSeconds]];
}

- (NSInteger)delayInMinutes {
    return [self delayInSeconds]/SECONDS_IN_MINUTE;
}

- (NSInteger)delayInSeconds {
    NSInteger result = [[NSDate date] timeIntervalSinceDate:self.lastUpdate];

    if ([[[NSCalendar currentCalendar] timeZone] isDaylightSavingTime]) {
        result -= SECONDS_IN_MINUTE*MINUTES_IN_HOUR;
    }

    return result;
}

@end
