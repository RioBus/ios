#import "BusLineBarView.h"

@interface BusLineBarView ()
@property (nonatomic, strong) UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *busLineBar;
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

- (void)appear {
    self.busLineBar.alpha = 1.0;
    self.lineNameLabel.alpha = 1.0;
    
    NSLog(@"appear y = %f", self.busLineBar.frame.origin.y);

    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.userInteractionEnabled = YES;
        self.busLineBar.frame = CGRectMake(self.busLineBar.frame.origin.x,
                                           self.containerView.frame.origin.y,
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


@end
