//
//  BusSuggestionsTable.h
//  riobus
//
//  Created by Vitor Marques de Miranda on 02/11/14.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BusSuggestionsTable : UITableView <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray* favorites;
@property (strong, nonatomic) NSMutableArray* recents;

-(void)addToRecentTable:(NSString*)newOne;

@end
