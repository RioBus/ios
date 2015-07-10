//
//  ReportProblemViewController.m
//  riobus
//
//  Created by Mario Cecchi on 7/10/15.
//  Copyright (c) 2015 Rio Bus. All rights reserved.
//

#import "ReportProblemViewController.h"

@interface ReportProblemViewController ()

@property (nonatomic) NSArray *problems;

@end

@implementation ReportProblemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.problems = @[@"Problema no ônibus", @"Localização no mapa errada", @"Itinerário errado", @"Problemas com o app", @"Outros"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UITableViewDataSource methods

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 1;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.problems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = self.problems[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 80;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSMutableParagraphStyle *style =  [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.firstLineHeadIndent = 15.0;
    style.headIndent = 15.0;
    style.tailIndent = -15.0;
    style.lineSpacing = 1.5;
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:@"Que tipo de problema você gostaria de reportar?"
                                                                   attributes:@{ NSParagraphStyleAttributeName: style}];

    UILabel *lblSectionName = [[UILabel alloc] init];
    lblSectionName.attributedText = attrText;
    lblSectionName.numberOfLines = 0;
    lblSectionName.lineBreakMode = NSLineBreakByWordWrapping;
    lblSectionName.textColor = [UIColor colorWithWhite:0.36 alpha:1.0];

    return lblSectionName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    

}

@end
