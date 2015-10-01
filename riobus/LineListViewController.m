#import "LineListViewController.h"

@interface LineListViewController ()
@property (nonatomic) NSArray *busLines;
@end

@implementation LineListViewController

- (NSArray *)busLines {
    if (!_busLines) {
        NSDictionary *trackedLinesDictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"tracked_bus_lines"];
        NSMutableArray *trackedLinesArray = [NSMutableArray arrayWithCapacity:trackedLinesDictionary.count];
        
        for (id line in trackedLinesDictionary) {
            [trackedLinesArray addObject:@{@"name": line, @"description": trackedLinesDictionary[line]}];
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                     ascending:YES];
        _busLines = [trackedLinesArray sortedArrayUsingDescriptors:@[sortDescriptor]];
    }
    
    return _busLines;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)didTapCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.busLines.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LineCell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.busLines[indexPath.row][@"name"];
    cell.detailTextLabel.text = self.busLines[indexPath.row][@"description"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.searchInput.text = self.busLines[indexPath.row][@"name"];
    [self.searchInput.delegate searchBarSearchButtonClicked:self.searchInput];
}

@end
