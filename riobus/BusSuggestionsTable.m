#import <Parse/Parse.h>
#import <PSTAlertController.h>
#import "BusSuggestionsTable.h"
#import "riobus-Swift.h"

@interface BusSuggestionsTable () <BusLineCellDelegate>
@property (nonatomic) NSString *favoriteLine;
@property (nonatomic) NSMutableArray *recentLines;
@property (nonatomic) NSArray *busLines;
@end

@implementation BusSuggestionsTable

static const int recentsSectionIndex = 0;
static const int allLinesSectionIndex = 1;
static const int totalSections = 2;
static const int recentItemsLimit = 5;
static const float animationDuration = 0.2;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.rowHeight = 60;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.delegate = self;
        self.dataSource = self;
        
        self.trackedBusLines = [[NSUserDefaults standardUserDefaults] objectForKey:@"tracked_bus_lines"];
        [self setBusLinesFromTrackedLines:self.trackedBusLines];
        
        self.favoriteLine = [[NSUserDefaults standardUserDefaults] objectForKey:@"favorite_line"];
        
        NSArray *savedRecents = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recents"];
        if (savedRecents) {
            self.recentLines = [savedRecents mutableCopy];
        }
        else {
            self.recentLines = [[NSMutableArray alloc] init];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateTrackedLines:)
                                                     name:@"RioBusDidUpdateTrackedLines"
                                                   object:nil];
    }
    
    return self;
}

- (void)show {
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.hidden = NO;
    [self setContentOffset:CGPointZero animated:NO];
    [UIView animateWithDuration:animationDuration animations:^{
        self.alpha = 1.0;
    }];
}

- (void)hide {
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [UIView animateWithDuration:animationDuration animations:^{
        self.alpha = 0.0;
    }];
}

- (void)synchronizePreferences {
    // Trim the size of the recent lines table by removing the last lines
    while (self.recentLines.count > recentItemsLimit) {
        [self.recentLines removeObjectAtIndex:0];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.recentLines forKey:@"Recents"];
    [[NSUserDefaults standardUserDefaults] setObject:self.favoriteLine forKey:@"favorite_line"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setObject:self.recentLines forKey:@"recentSearches"];
    [currentInstallation saveInBackground];
}

- (void)setBusLinesFromTrackedLines:(NSDictionary *)trackedLinesDictionary {
    NSMutableArray *trackedLinesArray = [NSMutableArray arrayWithCapacity:trackedLinesDictionary.count];
    
    for (id line in trackedLinesDictionary) {
        [trackedLinesArray addObject:@{@"name": line, @"description": trackedLinesDictionary[line]}];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    _busLines = [trackedLinesArray sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (void)didUpdateTrackedLines:(NSNotification *)notification {
    NSLog(@"ST Received notification that bus lines were updated.");
    self.trackedBusLines = (NSDictionary *)notification.object;
    [self setBusLinesFromTrackedLines:self.trackedBusLines];
    [self reloadData];
}

- (void)addToRecentTable:(NSString *)busLine {
    if ([self.recentLines containsObject:busLine]) {
        [self.recentLines removeObject:busLine];
        [self.recentLines addObject:busLine];
    }
    else {
        [self.recentLines addObject:busLine];
    }
    
    [self synchronizePreferences];
    [self reloadData];
}


#pragma mark - BusLineCell methods

- (void)makeFavorite:(NSString *)busLine {
    // Se já existe uma linha favorita definida
    if (self.favoriteLine) {
        PSTAlertController *alertController = [PSTAlertController alertWithTitle:[NSString stringWithFormat:NSLocalizedString(@"SET_LINE_AS_FAVORITE_ALERT_TITLE", nil), busLine] message:[NSString stringWithFormat:NSLocalizedString(@"SET_LINE_AS_FAVORITE_ALERT_MESSAGE", nil), self.favoriteLine]];
        [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"CANCEL", nil) style:PSTAlertActionStyleCancel handler:nil]];
        [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"SET_LINE_AS_FAVORITE_OK_BUTTON", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
            // Atualizar modelo
            [self addToRecentTable:busLine];
            self.favoriteLine = busLine;
            [self synchronizePreferences];
            
            // Atualizar view
            [self reloadData];
        }]];
        
        [alertController showWithSender:self controller:nil animated:YES completion:nil];
    }
    // Caso não exista uma linha favorita já definida
    else {
        // Atualizar modelo
        [self addToRecentTable:busLine];
        self.favoriteLine = busLine;
        [self synchronizePreferences];
        
        // Atualizar view
        [self reloadData];
    }
}

- (void)removeFromFavorites:(NSString *)busLine {
    NSString *confirmMessage = [NSString stringWithFormat:NSLocalizedString(@"REMOVE_LINE_FROM_FAVORITES_ALERT_MESSAGE", nil), busLine];
    PSTAlertController *alertController = [PSTAlertController alertWithTitle:NSLocalizedString(@"REMOVE_LINE_FROM_FAVORITES_ALERT_TITLE", nil) message:confirmMessage];
    [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"CANCEL", nil) style:PSTAlertActionStyleCancel handler:nil]];
    [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"REMOVE", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        // Atualizar modelo
        self.favoriteLine = nil;
        [self synchronizePreferences];
        
        // Atualizar view
        [self reloadData];
    }]];
    
    [alertController showWithSender:self controller:nil animated:YES completion:nil];
}


#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return totalSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == recentsSectionIndex) {
        return self.recentLines.count;
    }
    
    if (section == allLinesSectionIndex) {
        return self.busLines.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BusLineCell *cell = [tableView dequeueReusableCellWithIdentifier:BusLineCell.cellIdentifier];
    if (!cell) {
        cell = [[BusLineCell alloc] init];
        cell.delegate = self;
    }
    
    NSString *lineName, *lineDescription;
    
    if (indexPath.section == recentsSectionIndex) {
        lineName = self.recentLines[self.recentLines.count - indexPath.row - 1];
        lineDescription = self.trackedBusLines[lineName];
    }
    else if (indexPath.section == allLinesSectionIndex) {
        lineName = self.busLines[indexPath.row][@"name"];
        lineDescription = self.busLines[indexPath.row][@"description"];
    }
    
    BOOL isFavorite = [lineName isEqualToString:self.favoriteLine];
    [cell configureCellWithBusLine:lineName description:lineDescription isFavorite:isFavorite];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == recentsSectionIndex;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Atualizar modelo
        if (indexPath.section == recentsSectionIndex) {
            [self.recentLines removeObjectAtIndex:self.recentLines.count - indexPath.row - 1];
        }
        [self synchronizePreferences];
        
        // Atualizar view
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
}


#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.searchBar) {
        if (indexPath.section == recentsSectionIndex) {
            self.searchBar.text = self.recentLines[self.recentLines.count - indexPath.row - 1];
            [self.searchBar.delegate searchBarSearchButtonClicked:self.searchBar];
        }
        else if (indexPath.section == allLinesSectionIndex) {
            self.searchBar.text = self.busLines[indexPath.row][@"name"];
            [self.searchBar.delegate searchBarSearchButtonClicked:self.searchBar];
        }
    }
}

- (nullable NSString *)tableView:(nonnull UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == recentsSectionIndex && self.recentLines.count > 0) {
        return NSLocalizedString(@"MY_LINES_HEADER_TITLE", nil);
    }
    else if (section == allLinesSectionIndex) {
        return [NSString stringWithFormat:NSLocalizedString(@"ALL_LINES_HEADER_TITLE", nil), (unsigned long)self.busLines.count];
    }
    
    return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return @[@"★", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSIndexPath *newIndexPath;
    
    if ([title isEqualToString:@"★"]) {
        newIndexPath = [NSIndexPath indexPathForRow:0 inSection:recentsSectionIndex];
    }
    else {
        NSInteger newRow = [self indexForFirstChar:title];
        newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:allLinesSectionIndex];
    }
    
    [tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    return index;
}

/**
 * Returns the index for the location of the first item in the tracked lines array that begins with a certain character
 */
- (NSInteger)indexForFirstChar:(NSString *)character {
    NSUInteger count = 0;
    for (id line in self.busLines) {
        NSString *str = line[@"name"];
        if ([str hasPrefix:character]) {
            return count;
        }
        count++;
    }
    return 0;
}

#pragma mark - UISearchBar methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self hide];
    
    NSMutableArray<NSString *> *buses = [[NSMutableArray alloc] init];
    for (NSString *line in [[searchBar.text uppercaseString] componentsSeparatedByString:@","]) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![trimmedLine isEqualToString:@""]) {
            [buses addObject:trimmedLine];
        }
    }
    
    if (buses.count > 0) {
        [self.searchDelegate didSearchForBuses:buses];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self show];
    [self.searchDelegate didStartEditing];
    
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self hide];
    
    if (searchBar.text.length == 0) {
        [self.searchDelegate didCancelSearch];
    }
}

@end
