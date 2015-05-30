#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface BusSuggestionsTable : UITableView <UITableViewDelegate, UITableViewDataSource>

- (void)updateUserRecentsList;
- (void)updateUserFavoritesList;
- (void)updateOptionsList;
- (void)addToRecentTable:(NSString*)newOne;

@property (strong, nonatomic) UISearchBar* searchInput;
@property (strong, nonatomic) NSMutableArray* favorites;
@property (strong, nonatomic) NSMutableArray* recents;
@property (strong, nonatomic) NSMutableArray* options;

@end
