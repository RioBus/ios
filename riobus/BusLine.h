#import <Foundation/Foundation.h>

@interface BusLine : NSObject

- (instancetype)initWithLine:(NSString *)line andName:(NSString *)name;

@property (nonatomic) NSString *line;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *places;
@property (nonatomic) NSArray *shapes;

@end
