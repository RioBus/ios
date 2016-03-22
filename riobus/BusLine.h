#import <Foundation/Foundation.h>

@interface BusLine : NSObject

- (_Nullable instancetype)initWithName:(NSString * _Nonnull)line andDescription:(NSString * _Nullable)name;

@property (nonatomic) NSString *_Nonnull name;
@property (nonatomic) NSString *_Nullable lineDescription;
@property (nonatomic) NSArray *_Nullable places;
@property (nonatomic) NSArray *_Nullable shapes;

@end
