#import "BusLine.h"

@implementation BusLine

- (instancetype)initWithName:(NSString *)name andDescription:(NSString *)description {
    self = [super init];
    if (self) {
        _name = name;
        
        if (name && ![name isEqualToString:@""] && ![name isEqualToString:@"desconhecido"]) {
            _lineDescription = description.capitalizedString;
            
            // Enhance and parse line name removing parentheses and fetching destinations
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"s/\\[.*?\\]|\\(.*?\\)|\\{.*?\\}//g" options:NSRegularExpressionCaseInsensitive error:nil];
            NSString *lineDescriptionWithoutParentheses = [regex stringByReplacingMatchesInString:_lineDescription options:0 range:NSMakeRange(0, _lineDescription.length) withTemplate:@""];
            lineDescriptionWithoutParentheses = [lineDescriptionWithoutParentheses stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            // Parse the two locations from bus line description
            NSMutableArray *places = [[lineDescriptionWithoutParentheses componentsSeparatedByString:@" X "] mutableCopy];
            
            // Only assign location property if we have parsed two names
            if (places.count == 2) {
                // Trim the name strings
                for (int i=0; i<places.count; i++) {
                    places[i] = [places[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                }
                _places = places;
            }
        }
    }
    return self;
}

@end
