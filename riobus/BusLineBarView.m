#import "BusLineBarView.h"

@interface BusLineBarView ()
@property (nonatomic, strong) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *busLineBar;
@property (weak, nonatomic) IBOutlet UIView *directionBar;
@property (nonatomic, strong) NSMutableArray *customConstraints;
@end


@implementation BusLineBarView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _customConstraints = [[NSMutableArray alloc] init];
    
    UIView *view = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"BusLineBarView"
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
    
    NSLog(@"updateConstraints");
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
    self.busLineBar.frame = CGRectMake(self.busLineBar.frame.origin.x,
                                       self.containerView.frame.origin.y + 64,
                                       self.busLineBar.frame.size.width,
                                       self.busLineBar.frame.size.height);
    
    NSLog(@"layoutSubviews y = %f", self.busLineBar.frame.origin.y);
}

- (void)slideUpWithDestinationsVisible:(BOOL)destinationsVisible {
    self.busLineBar.alpha = 1.0;
    self.lineNameLabel.alpha = 1.0;
    
    CGFloat finalY;
    if (destinationsVisible) {
        finalY = self.containerView.frame.origin.y;
    } else {
        finalY = self.containerView.frame.origin.y + self.directionBar.frame.size.height;
    }
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.userInteractionEnabled = YES;
        self.busLineBar.frame = CGRectMake(self.busLineBar.frame.origin.x,
                                           finalY,
                                           self.busLineBar.frame.size.width,
                                           self.busLineBar.frame.size.height);
    } completion:^(BOOL finished){
        
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.lineNameLabel.alpha = 0.0;
        self.busLineBar.frame = CGRectMake(self.busLineBar.frame.origin.x,
                                           self.containerView.frame.origin.y + 64,
                                           self.busLineBar.frame.size.width,
                                           self.busLineBar.frame.size.height);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.busLineBar.alpha = 0.0;
        } completion:^(BOOL finished){
            self.userInteractionEnabled = NO;
        }];
    }];
}

- (IBAction)handleSwipeDown:(UISwipeGestureRecognizer *)sender {
    [self hide];
}

- (void)appearWithBusLine:(NSDictionary *)busLineInformation {
    if (busLineInformation[@"name"]) {
        self.lineNameLabel.text = [NSString stringWithFormat:@"%@ - %@", busLineInformation[@"line"], busLineInformation[@"name"]];
    } else {
        self.lineNameLabel.text = [NSString stringWithFormat:@"Linha %@", busLineInformation[@"line"]];
    }
    
    NSArray *places = busLineInformation[@"places"];
    if (places.count == 2) {
        [self.leftDestinationButton setTitle:places[0] forState:UIControlStateNormal];
        [self.rightDestinationButton setTitle:places[1] forState:UIControlStateNormal];
        [self slideUpWithDestinationsVisible:YES];
    } else {
        NSLog(@"No destination information");
        [self slideUpWithDestinationsVisible:NO];
    }

}

- (BOOL)selectDestination:(NSString *)destination {
    if ([self.leftDestinationButton.titleLabel.text isEqualToString:destination]) {
        self.leftDestinationButton.enabled = NO;
        self.rightDestinationButton.enabled = YES;
        return YES;
    }
    
    if ([self.rightDestinationButton.titleLabel.text isEqualToString:destination]) {
        self.leftDestinationButton.enabled = YES;
        self.rightDestinationButton.enabled = NO;
        return YES;
    }
    
    return NO;
}

- (IBAction)didTapLeftDestinationButton:(UIButton *)sender {
    if ([self.delegate busLineBarView:self didSelectDestination:sender.titleLabel.text]) {
        sender.enabled = NO;
        self.rightDestinationButton.enabled = YES;
    }
}

- (IBAction)didTapRightDestinationButton:(UIButton *)sender {
    if ([self.delegate busLineBarView:self didSelectDestination:sender.titleLabel.text]) {
        sender.enabled = NO;
        self.leftDestinationButton.enabled = YES;
    }
}

- (IBAction)didTapDirectionButton:(UIButton *)sender {
    if (self.leftDestinationButton.enabled) {
        if ([self.delegate busLineBarView:self didSelectDestination:self.leftDestinationButton.titleLabel.text]) {
            self.leftDestinationButton.enabled = NO;
            self.rightDestinationButton.enabled = YES;
        }
    } else if (self.rightDestinationButton.enabled) {
        if ([self.delegate busLineBarView:self didSelectDestination:self.rightDestinationButton.titleLabel.text]) {
            self.leftDestinationButton.enabled = YES;
            self.rightDestinationButton.enabled = NO;
        }
    }
}

@end
