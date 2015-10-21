#import <PSTAlertController.h>
#import "BusSuggestionsTable.h"
#import "riobus-Swift.h"

@interface BusSuggestionsTable()
@property (nonatomic) NSString *favoriteLine;
@property (nonatomic) NSMutableArray *recentLines;
@property (nonatomic) NSArray *busLines;
@end

@implementation BusSuggestionsTable

static const int recentsSectionIndex = 0;
static const int allLinesSectionIndex = 1;
static const int totalSections = 2;
static const int recentItemsLimit = 5;

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

- (void)synchronizePreferences {
    // Trim the size of the recent lines table by removing the last lines
    while (self.recentLines.count >= recentItemsLimit) {
        [self.recentLines removeObjectAtIndex:0];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.recentLines forKey:@"Recents"];
    [[NSUserDefaults standardUserDefaults] setObject:self.favoriteLine forKey:@"favorite_line"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

/**
 * Notification called when the application has received new bus lines from the server.
 * @param notification Notification contaning object with new bus lines.
 */
- (void)didUpdateTrackedLines:(NSNotification *)notification {
    NSLog(@"ST Received notification that bus lines were updated.");
    self.trackedBusLines = (NSDictionary *)notification.object;
    [self setBusLinesFromTrackedLines:self.trackedBusLines];
    [self reloadData];
}

/**
 * Adiciona uma linha no histórico caso ainda não tenha sido pesquisada.
 * Caso a linha já esteja no histórico, atualiza sua posição para lembrar que
 * foi a última pesquisada.
 * @param busLine Uma string com o número da linha.
 */
- (void)addToRecentTable:(NSString *)busLine {
    if ([self.recentLines containsObject:busLine]) {
        [self.recentLines removeObject:busLine];
        [self.recentLines addObject:busLine];
    }
    else {
        [self.recentLines addObject:busLine];
    }
    
    [self reloadData];
    [self synchronizePreferences];
}

- (void)makeLineFavorite:(UITapGestureRecognizer *)gestureRecognizer {
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:[gestureRecognizer locationInView:self]];
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    NSString *busLine = cell.textLabel.text;
    
    // Se já existe uma linha favorita definida
    if (self.favoriteLine) {
        PSTAlertController *alertController = [PSTAlertController alertWithTitle:[NSString stringWithFormat:@"Definir a linha %@ como favorita?", busLine] message:[NSString stringWithFormat:@"Isto irá remover a linha %@ dos favoritos.", self.favoriteLine]];
        [alertController addAction:[PSTAlertAction actionWithTitle:@"Cancelar" style:PSTAlertActionStyleCancel handler:nil]];
        [alertController addAction:[PSTAlertAction actionWithTitle:@"Redefinir" style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
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

- (void)removeLineFromFavorite:(UITapGestureRecognizer *)gestureRecognizer {
    NSString *confirmMessage = [NSString stringWithFormat:@"Você deseja mesmo remover a linha %@ dos favoritos?", self.favoriteLine];
    PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Excluir favorito" message:confirmMessage];
    [alertController addAction:[PSTAlertAction actionWithTitle:@"Cancelar" style:PSTAlertActionStyleCancel handler:nil]];
    [alertController addAction:[PSTAlertAction actionWithTitle:@"Excluir" style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
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
    UITableViewCell *cell;
    NSString *lineName;
    NSString *cellIdentifier;
    
    if (indexPath.section == recentsSectionIndex) {
        lineName = self.recentLines[self.recentLines.count - indexPath.row - 1];
    }
    else if (indexPath.section == allLinesSectionIndex) {
        lineName = self.busLines[indexPath.row][@"name"];
    }
    
    if ([lineName isEqualToString:self.favoriteLine]) {
        cellIdentifier = @"Favorite Line Cell";
    }
    else {
       cellIdentifier = @"Line Cell";
    }
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:22];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];

        UITapGestureRecognizer *tapped;
        if ([lineName isEqualToString:self.favoriteLine]) {
            cell.tintColor = [UIColor appGoldColor];
            tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeLineFromFavorite:)];
            cell.imageView.image = [[UIImage imageNamed:@"StarFilled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        else {
            cell.tintColor = [UIColor colorWithWhite:0.9 alpha:1.0];
            tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(makeLineFavorite:)];
            cell.imageView.image = [[UIImage imageNamed:@"Star"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
        cell.imageView.isAccessibilityElement = YES;
        cell.imageView.accessibilityTraits = UIAccessibilityTraitButton;
        if ([cell respondsToSelector:NSSelectorFromString(@"setAcessibilityElements")]) {
            cell.accessibilityElements = @[cell.textLabel, cell.imageView];
        }
        cell.imageView.userInteractionEnabled = YES;
    }
    
    cell.textLabel.text = lineName;

    if (indexPath.section == recentsSectionIndex) {
        cell.detailTextLabel.text = self.trackedBusLines[lineName];
    }
    else if (indexPath.section == allLinesSectionIndex) {
        cell.detailTextLabel.text = self.busLines[indexPath.row][@"description"];
    }
    
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
    
    if (self.searchInput) {
        if (indexPath.section == recentsSectionIndex) {
            self.searchInput.text = self.recentLines[self.recentLines.count - indexPath.row - 1];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        }
        else if (indexPath.section == allLinesSectionIndex) {
            self.searchInput.text = self.busLines[indexPath.row][@"name"];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        }
    }
}

- (nullable NSString *)tableView:(nonnull UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == recentsSectionIndex && self.recentLines.count > 0) {
        return @"Minhas linhas";
    }
    else if (section == allLinesSectionIndex) {
        return [NSString stringWithFormat:@"Todas as linhas (%ld online)", (unsigned long)self.busLines.count];
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

@end
