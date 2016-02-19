#import <UIKit/UIKit.h>

@protocol BusSuggestionsTableDelegate <NSObject>

- (void)didSearchForBuses:(NSArray<NSString *> *)buses;
- (void)didCancelSearch;
- (void)didStartEditing;

@end

IB_DESIGNABLE
@interface BusSuggestionsTable : UITableView <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

- (void)addToRecentTable:(NSString *)busLine;

@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) NSDictionary *trackedBusLines;
@property (nonatomic) id<BusSuggestionsTableDelegate> searchDelegate;

@end
