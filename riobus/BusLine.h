#import <Foundation/Foundation.h>

@interface BusLine : NSObject

- (instancetype)initWithName:(NSString *)line andDescription:(NSString *)name;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *lineDescription;
@property (nonatomic) NSArray *places;
@property (nonatomic) NSArray *shapes;

@end
