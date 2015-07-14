#import <Google/Analytics.h>
#import "ReportProblemViewController.h"
#import "ReportDetailViewController.h"

@interface ReportProblemViewController ()

@property (nonatomic) NSArray *problems;

@end

@implementation ReportProblemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.problems = @[@{ @"descricao": @"Não encontrei uma linha", @"tipo": @"prefeitura" },
                      @{ @"descricao": @"Localização incorreta no mapa", @"tipo": @"prefeitura" },
                      @{ @"descricao": @"Itinerário incorreto", @"tipo": @"prefeitura" },
                      @{ @"descricao": @"Problemas com o aplicativo", @"tipo": @"app" },
                      @{ @"descricao": @"Outro", @"tipo": @"outro" }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Reportar problema"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)didTapCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowReportDetail"]) {
        ReportDetailViewController *detailViewController = segue.destinationViewController;

        NSIndexPath *problemIndexPath = [self.tableView indexPathForSelectedRow];
        detailViewController.problem = self.problems[problemIndexPath.row];
    }
}


#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.problems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = self.problems[indexPath.row][@"descricao"];
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
    lblSectionName.backgroundColor = self.tableView.backgroundColor;

    return lblSectionName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ShowReportDetail" sender:self];
}
@end
