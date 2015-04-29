//
//  BusSuggestionsTable.m
//  riobus
//
//  Created by Vitor Marques de Miranda on 02/11/14.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "BusSuggestionsTable.h"

#define FAVORITES_SECTION        0
#define RECENTS_SECTION          1
#define OPTIONS_SECTION          2
#define NUMBER_OF_SECTIONS       3

#define RECENT_ITEMS_LIMIT       5

@implementation BusSuggestionsTable

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.rowHeight = 45;
        self.options = [[NSMutableArray alloc] init];
        self.delegate = self;
        self.dataSource = self;
        
        _favorites = [self userFavoritesList];
        _recents = [self userRecentsList];
        
        [self updateOptionsList];
        
        [self reloadData];
    }
    return self;
}

-(void)updateUserRecentsList{
    [[NSUserDefaults standardUserDefaults] setObject:self.recents forKey:@"Recents"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self updateOptionsList];
}

-(void)updateUserFavoritesList{
    [[NSUserDefaults standardUserDefaults] setObject:self.favorites forKey:@"Favorites"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self updateOptionsList];
}

-(void)updateOptionsList {
    if (self.recents.count) {
        if (!self.options.count) [self.options addObject:@"Limpar recentes"];
    } else {
        [self.options removeAllObjects];
    }
}

-(NSMutableArray*)userFavoritesList{
    NSArray* tempFavorites = [[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"];
    if (tempFavorites) return [tempFavorites mutableCopy];
    else return [[NSMutableArray alloc] init];
}

-(NSMutableArray*)userRecentsList{
    NSArray* tempRecents = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recents"];
    
    if (tempRecents) return [tempRecents mutableCopy];
    else return [[NSMutableArray alloc] init];
}

-(void)addToRecentTable:(NSString*)newOne{
    if (![_recents containsObject:newOne] && ![_favorites containsObject:newOne]){
        while ([_recents count]>=RECENT_ITEMS_LIMIT) [_recents removeObjectAtIndex:0];
        [_recents addObject:newOne];
        [self updateUserRecentsList];
        [self reloadData];
    }
}

-(void)moveFromRecentToFavoriteTable:(UITapGestureRecognizer*)sender{
    NSString* newItem = [_recents objectAtIndex:sender.view.tag];
    [_recents removeObjectAtIndex:sender.view.tag];
    [self updateUserRecentsList];
    if (![_favorites containsObject:newItem]){
        [_favorites addObject:newItem];
        [self updateUserFavoritesList];
    }
    [self reloadData];
}

-(void)removeFromFavoriteTable:(UITapGestureRecognizer*)sender{
    [_favorites removeObjectAtIndex:sender.view.tag];
    [self updateUserFavoritesList];
    [self reloadData];
}

- (void)clearRecentSearches {
    // TODO confirmar
    [_recents removeAllObjects];
    [self updateUserRecentsList];
    [self reloadData];
}

-(UIButton*)generateFavoriteButton:(BOOL)favorite forIndex:(NSInteger)index atFrame:(CGRect)frame{
    UIButton* button = [[UIButton alloc] initWithFrame:frame];
    button.tag = index;
    
    if (favorite){
        [button setBackgroundImage:[UIImage imageNamed:@"bookmark"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(removeFromFavoriteTable:) forControlEvents:UIControlEventTouchDown];
    }
    else{
        [button setBackgroundImage:[UIImage imageNamed:@"recent"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(moveFromRecentToFavoriteTable:) forControlEvents:UIControlEventTouchDown];
    }
    
    return button;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUMBER_OF_SECTIONS;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == FAVORITES_SECTION) return self.favorites.count;
    if (section == RECENTS_SECTION  ) return self.recents.count;
    if (section == OPTIONS_SECTION  ) return self.options.count;
    return 0;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath{
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.item;

    if (indexPath.section == FAVORITES_SECTION) {
        cell.imageView.image = [UIImage imageNamed:@"bookmark.png"];
        cell.textLabel.text = self.favorites[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFromFavoriteTable:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    } else if (indexPath.section == RECENTS_SECTION) {
        cell.imageView.image = [UIImage imageNamed:@"recent.png"];
        cell.textLabel.text = self.recents[indexPath.item];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveFromRecentToFavoriteTable:)];
        tapped.numberOfTapsRequired = 1;
        [cell.imageView addGestureRecognizer:tapped];
    } else if (indexPath.section == OPTIONS_SECTION) {
        cell.imageView.image = nil;
        cell.textLabel.text = self.options[indexPath.item];
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UISearchBar* searchInput;
    for (UIView* view in [self.superview subviews])
        if ([view isKindOfClass:[UISearchBar class]]) searchInput = (UISearchBar *)view;
    
    if (searchInput){
        if (indexPath.section == FAVORITES_SECTION) {
            [searchInput setText:_favorites[[indexPath row]]];
            [searchInput.delegate searchBarSearchButtonClicked:searchInput];
        } else if (indexPath.section == RECENTS_SECTION) {
            [searchInput setText:_recents[[indexPath row]]];
            [searchInput.delegate searchBarSearchButtonClicked:searchInput];
        } else if (indexPath.section == OPTIONS_SECTION) {
            [self clearRecentSearches];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
