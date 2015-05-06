#import <UIKit/UIKit.h>

@interface BusSuggestionsTable : UITableView <UITableViewDelegate, UITableViewDataSource>

-(void)updateUserRecentsList;
-(void)updateUserFavoritesList;
-(void)updateOptionsList;

@property (strong, nonatomic) NSMutableArray* favorites;
@property (strong, nonatomic) NSMutableArray* recents;
@property (strong, nonatomic) NSMutableArray* options;

-(void)addToRecentTable:(NSString*)newOne;

@end
