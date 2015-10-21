#import "BusData.h"

static const int secondsInMinute = 60;
static const int minutesInHour = 60;
static const int hoursInDay = 24;

@implementation BusData

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSDateFormatter *jsonDateFormat = [[NSDateFormatter alloc] init];
        jsonDateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

        self.lastUpdate = [jsonDateFormat dateFromString:dictionary[@"timeStamp"]];
        if (self.lastUpdate) {
            
        }
        self.order = dictionary[@"order"];
        self.lineNumber = dictionary[@"line"];
        self.velocity = dictionary[@"speed"];
        self.location = [[CLLocation alloc] initWithLatitude:[dictionary[@"latitude"] doubleValue]
                                                   longitude:[dictionary[@"longitude"] doubleValue]];
        self.direction = dictionary[@"direction"];
        self.sense = dictionary[@"sense"];
    }
    return self;
}

- (NSString *)destination {
    // Verifica se a linha possui informação de sentido
    if (![self.sense isEqualToString:@""] && ![self.sense isEqualToString:@"desconhecido"]) {
        // Tirar informação entre parênteses do nome da linha
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"s/\\[.*?\\]|\\(.*?\\)|\\{.*?\\}//g" options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *lineNameWithoutParentheses = [regex stringByReplacingMatchesInString:self.sense options:0 range:NSMakeRange(0, self.sense.length) withTemplate:@""];
        lineNameWithoutParentheses = [lineNameWithoutParentheses stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSArray *places = [lineNameWithoutParentheses componentsSeparatedByString:@" X "];
        if (places.count == 2) {
            return places[1];
        }
    }
    
    return nil;
}

- (void)setSense:(NSString *)sense {
    _sense = sense.capitalizedString;
}

- (NSString *)humanReadableDelay {
    return [BusData humanReadableStringForSeconds:self.delayInSeconds];
}

- (NSInteger)delayInMinutes {
    return self.delayInSeconds / secondsInMinute;
}

- (NSInteger)delayInSeconds {
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate];
}

+ (NSString *)humanReadableStringForTime:(NSInteger)value ofType:(NSString *)type {
    if ([type isEqualToString:@"segundo"] || ([type isEqualToString:@"minuto"] && value == 1)) {
        return @"agora";
    }
    return [NSString stringWithFormat:@"%ld %@ atrás", (long)value, (value == 1 ? type : [type stringByAppendingString:@"s"])];
}

+ (NSString *)humanReadableStringForSeconds:(NSInteger)seconds {
    NSInteger value = seconds;
    
    if (value < secondsInMinute) {
        return [BusData humanReadableStringForTime:value ofType:@"segundo"];
    }
    
    value /= secondsInMinute;
    
    if (value < minutesInHour) {
        return [BusData humanReadableStringForTime:value ofType:@"minuto"];
    }
    
    value /= minutesInHour;
    
    if (value < hoursInDay) {
        return [BusData humanReadableStringForTime:value ofType:@"hora"];
    }
    
    value /= hoursInDay;
    
    return [BusData humanReadableStringForTime:value ofType:@"dia"];
}

@end
