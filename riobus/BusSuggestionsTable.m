#import "BusSuggestionsTable.h"

@implementation BusSuggestionsTable

static const int favoritesSectionIndex = 0;
static const int recentsSectionIndex = 1;
static const int optionsSectionIndex = 2;
static const int totalSections = 3;
static const int recentItemsLimit = 5;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.rowHeight = 45;
        self.delegate = self;
        self.dataSource = self;
        
        NSArray* savedFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"];
        if (savedFavorites) {
           self.favorites = [savedFavorites mutableCopy];
        }
        else {
            self.favorites = [[NSMutableArray alloc] init];
        }
        
        NSArray* savedRecents = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recents"];
        if (savedRecents) {
            self.recents = [savedRecents mutableCopy];
        }
        else {
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

- (void)addToRecentTable:(NSString *)busLine {
    if (![self.recents containsObject:busLine] && ![self.favorites containsObject:busLine]) {
        while (self.recents.count >= recentItemsLimit) {
            [self.recents removeObjectAtIndex:0];
        }
        
        [self.recents addObject:busLine];
        [self updateUserRecentsList];
        
        [self reloadData];
    }
}

- (void)moveFromRecentToFavoriteTable:(UITapGestureRecognizer *)sender {
    NSInteger itemIndexRecents = sender.view.tag;
    NSString* newItem = self.recents[itemIndexRecents];
    [self.recents removeObjectAtIndex:itemIndexRecents];

    [self updateUserRecentsList];
    
    if (![self.favorites containsObject:newItem]) {
        [self.favorites addObject:newItem];
        [self updateUserFavoritesList];
    }
    
    [self reloadData];
}

- (void)removeFromFavoriteTable:(UITapGestureRecognizer *)sender {
    [self.favorites removeObjectAtIndex:sender.view.tag];
    [self updateUserFavoritesList];
    [self reloadData];
}

- (void)clearRecentSearches {
    [self.recents removeAllObjects];
    [self updateUserRecentsList];
    [self reloadData];
}


#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return totalSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == favoritesSectionIndex) {
        return self.favorites.count;
    }
    
    if (section == recentsSectionIndex) {
        return self.recents.count;
    }
    
    if (section == optionsSectionIndex) {
        return self.recents.count > 0;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.item;

    if (indexPath.section == favoritesSectionIndex) {
        cell.imageView.image = [[UIImage imageNamed:@"FavoriteMarker"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = self.favorites[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFromFavoriteTable:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    }
    else if (indexPath.section == recentsSectionIndex) {
        cell.imageView.image = [UIImage imageNamed:@"FavoriteMarker"];
        cell.textLabel.text = self.recents[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveFromRecentToFavoriteTable:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    }
    else if (indexPath.section == optionsSectionIndex) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"Limpar recentes";
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchInput) {
        if (indexPath.section == favoritesSectionIndex) {
            [self.searchInput setText:self.favorites[[indexPath row]]];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        }
        else if (indexPath.section == recentsSectionIndex) {
            [self.searchInput setText:self.recents[[indexPath row]]];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        }
        else if (indexPath.section == optionsSectionIndex) {
            [self clearRecentSearches];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
