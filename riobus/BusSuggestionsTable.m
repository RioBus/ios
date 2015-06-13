#import <PSTAlertController.h>
#import "BusSuggestionsTable.h"
#import "riobus-Swift.h"

@interface BusSuggestionsTable()

@property (nonatomic) NSString *favoriteLine;
@property (nonatomic) NSMutableArray *recentLines;

@end

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
        
        self.favoriteLine  = [[NSUserDefaults standardUserDefaults] objectForKey:@"favorite_line"];
        
        NSArray *savedRecents = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recents"];
        if (savedRecents) {
            self.recentLines = [savedRecents mutableCopy];
        }
        else {
            self.recentLines = [[NSMutableArray alloc] init];
        }
    }
    
    return self;
}

- (void)syncrhonizePreferences {
    // Trim the size of the recent lines table by removing the last lines
    while (self.recentLines.count >= recentItemsLimit) {
        [self.recentLines removeObjectAtIndex:0];
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.recentLines forKey:@"Recents"];
    [[NSUserDefaults standardUserDefaults] setObject:self.favoriteLine forKey:@"favorite_line"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)addToRecentTable:(NSString *)busLine {
    // Verifica se a linha já não está salva
    if (![self.recentLines containsObject:busLine] && ![self.favoriteLine isEqualToString:busLine]) {
        
        [self.recentLines addObject:busLine];
        [self syncrhonizePreferences];
        
        [self reloadData];
    }
}

- (void)makeLineFavorite:(UITapGestureRecognizer *)sender {
    NSInteger itemIndexRecents = sender.view.tag;
    NSString *busLine = self.recentLines[itemIndexRecents];
    
    if (self.favoriteLine) {
        PSTAlertController *alertController = [PSTAlertController alertWithTitle:[NSString stringWithFormat:@"Definir a linha %@ como favorita?", busLine] message:[NSString stringWithFormat:@"Isto irá remover a linha %@ dos favoritos.", self.favoriteLine]];
        [alertController addAction:[PSTAlertAction actionWithTitle:@"Cancelar" style:PSTAlertActionStyleCancel handler:nil]];
        [alertController addAction:[PSTAlertAction actionWithTitle:@"Redefinir" style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
            [self.recentLines removeObjectAtIndex:itemIndexRecents];
            [self.recentLines addObject:self.favoriteLine];
            self.favoriteLine = busLine;
            [self syncrhonizePreferences];
            [self reloadData];
        }]];
        
        [alertController showWithSender:self controller:nil animated:YES completion:nil];
    }
    else {
        self.favoriteLine = busLine;
        [self.recentLines removeObjectAtIndex:itemIndexRecents];
        [self syncrhonizePreferences];
        [self reloadData];
    }
}

- (void)removeLineFromFavorite:(UITapGestureRecognizer *)sender {
    NSString *confirmMessage = [NSString stringWithFormat:@"Você deseja mesmo remover a linha %@ dos favoritos?", self.favoriteLine];
    PSTAlertController *alertController = [PSTAlertController alertWithTitle:@"Excluir favorito" message:confirmMessage];
    [alertController addAction:[PSTAlertAction actionWithTitle:@"Cancelar" style:PSTAlertActionStyleCancel handler:nil]];
    [alertController addAction:[PSTAlertAction actionWithTitle:@"Excluir" style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        if (self.favoriteLine) {
            [self.recentLines addObject:self.favoriteLine];
        }
        self.favoriteLine = nil;
        [self syncrhonizePreferences];
        [self reloadData];
    }]];
    
    [alertController showWithSender:self controller:nil animated:YES completion:nil];
}

- (void)clearRecentSearches {
    [self.recentLines removeAllObjects];
    [self syncrhonizePreferences];
    [self reloadData];
}


#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return totalSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == favoritesSectionIndex) {
        return self.favoriteLine != nil;
    }
    
    if (section == recentsSectionIndex) {
        return self.recentLines.count;
    }
    
    if (section == optionsSectionIndex) {
        return self.recentLines.count > 0;
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
        cell.imageView.image = [UIImage imageNamed:@"StarFilled"];
        cell.tintColor = [UIColor appGoldColor];
        cell.textLabel.text = self.favoriteLine;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeLineFromFavorite:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    }
    else if (indexPath.section == recentsSectionIndex) {
        cell.imageView.image = [UIImage imageNamed:@"Star"];
        cell.tintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        cell.textLabel.text = self.recentLines[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(makeLineFavorite:)];
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
    return indexPath.section != optionsSectionIndex;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        
        if (indexPath.section == favoritesSectionIndex) {
            self.favoriteLine = nil;
        }
        else {
            [self.recentLines removeObjectAtIndex:indexPath.row];
        }
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self syncrhonizePreferences];
        
        [tableView endUpdates]; // FIXME: endUpdates não atualiza tag da célula
    }
}


#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchInput) {
        if (indexPath.section == favoritesSectionIndex) {
            (self.searchInput).text = self.favoriteLine;
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        }
        else if (indexPath.section == recentsSectionIndex) {
            (self.searchInput).text = self.recentLines[indexPath.row];
            [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
        }
        else if (indexPath.section == optionsSectionIndex) {
            [self clearRecentSearches];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
