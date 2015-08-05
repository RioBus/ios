#import "BusLine.h"

@implementation BusLine

- (instancetype)initWithLine:(NSString *)line andName:(NSString *)name {
    self = [super init];
    if (self) {
        _line = line;
        
        if (name && ![name isEqualToString:@""] && ![name isEqualToString:@"desconhecido"]) {
            _name = name.capitalizedString;
            
            // Enhance and parse line name removing parentheses and fetching destinations
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"s/\\[.*?\\]|\\(.*?\\)|\\{.*?\\}//g" options:NSRegularExpressionCaseInsensitive error:nil];
            NSString *lineNameWithoutParentheses = [regex stringByReplacingMatchesInString:_name options:0 range:NSMakeRange(0, _name.length) withTemplate:@""];
            lineNameWithoutParentheses = [lineNameWithoutParentheses stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            _places = [lineNameWithoutParentheses componentsSeparatedByString:@" X "];
        }
    }
    return self;
}

@end
