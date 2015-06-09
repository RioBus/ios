#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface BusSuggestionsTable : UITableView <UITableViewDelegate, UITableViewDataSource>

- (void)updateUserRecentsList;
- (void)updateUserFavoritesList;
- (void)addToRecentTable:(NSString *)busLine;

@property (nonatomic) UISearchBar *searchInput;
@property (nonatomic) NSMutableArray *favorites;
@property (nonatomic) NSMutableArray *recents;

@end
