#import "BusSuggestionsTable.h"

#define FAVORITES_SECTION        0
#define RECENTS_SECTION          1
#define OPTIONS_SECTION          2
#define NUMBER_OF_SECTIONS       3

#define RECENT_ITEMS_LIMIT       5

@implementation BusSuggestionsTable

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.rowHeight = 45;
        self.delegate = self;
        self.dataSource = self;
        
        NSArray* savedFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"];
        if (savedFavorites) {
           self.favorites = [savedFavorites mutableCopy];
        } else {
            self.favorites = [[NSMutableArray alloc] init];
        }
        
        NSArray* savedRecents = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recents"];
        if (savedRecents) {
            self.recents = [savedRecents mutableCopy];
        } else {
            self.recents = [[NSMutableArray alloc] init];
        }
    }
    
    return self;
}

- (void)updateUserRecentsList {
    [[NSUserDefaults standardUserDefaults] setObject:self.recents forKey:@"Recents"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateUserFavoritesList {
    [[NSUserDefaults standardUserDefaults] setObject:self.favorites forKey:@"Favorites"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)addToRecentTable:(NSString*)newOne {
    if (![self.recents containsObject:newOne] && ![self.favorites containsObject:newOne]) {
        while (self.recents.count >= RECENT_ITEMS_LIMIT) [self.recents removeObjectAtIndex:0];
        [self.recents addObject:newOne];
        [self updateUserRecentsList];
        
        [self reloadData];
    }
}

- (void)moveFromRecentToFavoriteTable:(UITapGestureRecognizer*)sender {
    NSInteger itemIndexRecents = sender.view.tag;
    NSString* newItem = self.recents[itemIndexRecents];
    [self.recents removeObjectAtIndex:itemIndexRecents];

    [self updateUserRecentsList];
    
    if (![self.favorites containsObject:newItem]){
        [self.favorites addObject:newItem];
        [self updateUserFavoritesList];
    }
    
    [self reloadData];

}

- (void)removeFromFavoriteTable:(UITapGestureRecognizer*)sender {
    [self.favorites removeObjectAtIndex:sender.view.tag];
    [self updateUserFavoritesList];
    [self reloadData];
}

- (void)clearRecentSearches {
    [self.recents removeAllObjects];
    [self updateUserRecentsList];
    [self reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == FAVORITES_SECTION)
        return self.favorites.count;
    if (section == RECENTS_SECTION)
        return self.recents.count;
    if (section == OPTIONS_SECTION)
        return self.recents.count > 0;
    
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.item;

    if (indexPath.section == FAVORITES_SECTION) {
        cell.imageView.image = [[UIImage imageNamed:@"FavoriteMarker"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = self.favorites[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFromFavoriteTable:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    } else if (indexPath.section == RECENTS_SECTION) {
        cell.imageView.image = [UIImage imageNamed:@"FavoriteMarker"];
        cell.textLabel.text = self.recents[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveFromRecentToFavoriteTable:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    } else if (indexPath.section == OPTIONS_SECTION) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"Limpar recentes";
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchInput) {
        if (indexPath.section == FAVORITES_SECTION) {
            [self.searchInput setText:_favorites[[indexPath row]]];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        } else if (indexPath.section == RECENTS_SECTION) {
            [self.searchInput setText:_recents[[indexPath row]]];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        } else if (indexPath.section == OPTIONS_SECTION) {
            [self clearRecentSearches];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
