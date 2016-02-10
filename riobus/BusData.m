#import "BusData.h"

static NSDateFormatter *jsonDateFormatter;

@implementation BusData

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        if (!jsonDateFormatter) {
            jsonDateFormatter = [[NSDateFormatter alloc] init];
            jsonDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
            jsonDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        }

        self.lastUpdate = [jsonDateFormatter dateFromString:dictionary[@"timeStamp"]];

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

@end
