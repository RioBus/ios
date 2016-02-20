#import "BusLineBar.h"
#import "BusLine.h"

@interface BusLineBar ()

@property (nonatomic, strong) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *busLineBar;
@property (weak, nonatomic) IBOutlet UIView *directionBar;
@property (weak, nonatomic) IBOutlet UILabel *avisoSentidoLabel;
@property (weak, nonatomic) IBOutlet UIButton *directionButton;
@property (nonatomic, strong) NSMutableArray *customConstraints;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *barHeightConstraint;

@end

@implementation BusLineBar

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _customConstraints = [[NSMutableArray alloc] init];
    
    UIView *view = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"BusLineBar"
                                                     owner:self
                                                   options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    
    if (view != nil) {
        _containerView = view;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        [self setNeedsUpdateConstraints];
    }
    
    self.busLineBar.alpha = 0.0;
    self.userInteractionEnabled = NO;
    
}

- (void)updateConstraints {
    [self removeConstraints:self.customConstraints];
    [self.customConstraints removeAllObjects];
    
    if (self.containerView != nil) {
        UIView *view = self.containerView;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        
        [self.customConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:
          @"H:|[view]|" options:0 metrics:nil views:views]];
        [self.customConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:
          @"V:|[view]|" options:0 metrics:nil views:views]];
        
        [self addConstraints:self.customConstraints];
    }
    
    [super updateConstraints];
}

- (void)slideUpWithDestinationsAvailable:(BOOL)destinationsAvailable {
    self.busLineBar.alpha = 1.0;
    self.lineNameLabel.alpha = 1.0;

    if (destinationsAvailable) {
        self.avisoSentidoLabel.text = NSLocalizedString(@"SELECT_DIRECTION", nil);
        self.avisoSentidoLabel.hidden = NO;
        self.avisoSentidoLabel.alpha = 1.0;
        self.directionButton.alpha = 0.0;
        self.leftDestinationButton.alpha = 0.0;
        self.rightDestinationButton.alpha = 0.0;
    }
    else {
        self.avisoSentidoLabel.text = NSLocalizedString(@"SELECT_DIRECTION_UNAVAILABLE", nil);
        self.avisoSentidoLabel.hidden = NO;
        self.avisoSentidoLabel.alpha = 1.0;
        self.directionButton.alpha = 0.0;
        self.leftDestinationButton.alpha = 0.0;
        self.rightDestinationButton.alpha = 0.0;
    }
    
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.busLineBar.frame = CGRectMake(self.busLineBar.frame.origin.x,
                                           self.containerView.frame.origin.y + self.barHeightConstraint.constant,
                                           self.busLineBar.frame.size.width,
                                           self.busLineBar.frame.size.height);
    } completion:^(BOOL finished){
        self.userInteractionEnabled = YES;
        if (destinationsAvailable) {
            [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.avisoSentidoLabel.alpha = 0.0;
                self.directionButton.alpha = 1.0;
                self.leftDestinationButton.alpha = 1.0;
                self.rightDestinationButton.alpha = 1.0;
            } completion:nil];
        }
        
        if ([self.delegate respondsToSelector:@selector(busLineBarView:didAppear:)]) {
            [self.delegate busLineBarView:self didAppear:YES];
        }
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.lineNameLabel.alpha = 0.0;
        self.busLineBar.frame = CGRectMake(self.busLineBar.frame.origin.x,
                                           self.containerView.frame.origin.y + 64,
                                           self.busLineBar.frame.size.width,
                                           self.busLineBar.frame.size.height);
        
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.busLineBar.alpha = 0.0;
        } completion:^(BOOL finished){
            self.userInteractionEnabled = NO;
            
            if ([self.delegate respondsToSelector:@selector(busLineBarView:didAppear:)]) {
                [self.delegate busLineBarView:self didAppear:NO];
            }
        }];
    }];
}

- (IBAction)handleSwipeDown:(UISwipeGestureRecognizer *)sender {
    [self hide];
}

- (IBAction)didTapHideBarButton:(UIButton *)sender {
    [self hide];
}

- (void)appearWithBusLine:(BusLine *)busLine {
    if (busLine.lineDescription) {
        self.lineNameLabel.text = [NSString stringWithFormat:@"%@ - %@", busLine.name, busLine.lineDescription];
    }
    else {
        self.lineNameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LINE_BAR_SEARCH_FOR_LINE_TITLE", nil), busLine.name];
    }
    
    self.leftDestinationButton.selected = YES;
    self.rightDestinationButton.selected = YES;
    
    if (busLine.places.count == 2) {
        [self.leftDestinationButton setTitle:busLine.places[0] forState:UIControlStateNormal];
        [self.rightDestinationButton setTitle:busLine.places[1] forState:UIControlStateNormal];
        [self slideUpWithDestinationsAvailable:YES];
    }
    else {
        [self slideUpWithDestinationsAvailable:NO];
    }

}

- (NSArray *)selectedDestinations {
    NSMutableArray *destinations = [[NSMutableArray alloc] initWithCapacity:2];
    
    if (self.leftDestinationButton.selected) {
        [destinations addObject:self.leftDestinationButton.titleLabel.text];
    }
    
    if (self.rightDestinationButton.selected) {
        [destinations addObject:self.rightDestinationButton.titleLabel.text];
    }
    
    return destinations;
}

- (IBAction)didTapLeftDestinationButton:(UIButton *)sender {
    self.leftDestinationButton.selected = !self.leftDestinationButton.selected;
    
    // If the two destinations are disabled, enable the opposite one
    if (!self.leftDestinationButton.selected && !self.rightDestinationButton.selected) {
        self.rightDestinationButton.selected = YES;
    }
    
    [self.delegate busLineBarView:self didSelectDestinations:self.selectedDestinations];
}

- (IBAction)didTapRightDestinationButton:(UIButton *)sender {
    self.rightDestinationButton.selected = !self.rightDestinationButton.selected;
    
    // If the two destinations are disabled, enable the opposite one
    if (!self.leftDestinationButton.selected && !self.rightDestinationButton.selected) {
        self.leftDestinationButton.selected = YES;
    }
    
    [self.delegate busLineBarView:self didSelectDestinations:self.selectedDestinations];
}

- (IBAction)didTapDirectionButton:(UIButton *)sender {
    if (!self.leftDestinationButton.selected && self.rightDestinationButton.selected) {
        self.leftDestinationButton.selected = YES;
        self.rightDestinationButton.selected = NO;
        
        [self.delegate busLineBarView:self didSelectDestinations:self.selectedDestinations];
    }
    else if (!self.rightDestinationButton.selected) {
        self.leftDestinationButton.selected = NO;
        self.rightDestinationButton.selected = YES;
        
        [self.delegate busLineBarView:self didSelectDestinations:self.selectedDestinations];
    }
}

@end
