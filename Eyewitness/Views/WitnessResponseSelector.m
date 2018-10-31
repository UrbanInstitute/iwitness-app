#import "WitnessResponseSelector.h"
#import "WitnessResponseButton.h"
#import "EyewitnessTheme.h"

@interface WitnessResponseSelector ()
@property (nonatomic, weak, readwrite) UIButton *yesButton, *noButton;
@property (nonatomic, strong, readwrite) UIButton *notSureButton;
@property (nonatomic, readwrite) WitnessResponse selectedResponse;
@end

@implementation WitnessResponseSelector

- (void)awakeFromNib {
    [self setUp];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setUp];
    }

    return self;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.yesButton.enabled = self.notSureButton.enabled = self.noButton.enabled = enabled;
}

- (void)setAllowNotSureResponse:(BOOL)allowNotSureResponse {
    _allowNotSureResponse = allowNotSureResponse;
    if (allowNotSureResponse) {
        [self addSubview:self.notSureButton];
    } else {
        [self.notSureButton removeFromSuperview];
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize buttonSize = CGSizeMake(225.f, 60.f);
    CGFloat interButtonPadding = 20.f;
    [self.yesButton resizeTo:buttonSize];
    [self.noButton resizeTo:buttonSize];
    [self.notSureButton resizeTo:buttonSize];

    CGFloat totalWidth = CGRectGetWidth(self.bounds);
    NSUInteger numberOfButtons = self.allowNotSureResponse ? 3 : 2;
    CGFloat margin = (totalWidth - buttonSize.width * numberOfButtons - interButtonPadding * (numberOfButtons - 1)) / 2;

    self.yesButton.frame = CGRectIntegral(CGRectMake(margin, 0, buttonSize.width, buttonSize.height));
    self.noButton.frame = CGRectIntegral(CGRectMake(margin + buttonSize.width + interButtonPadding, 0, buttonSize.width, buttonSize.height));
    self.notSureButton.frame = CGRectIntegral(CGRectMake(margin + (buttonSize.width + interButtonPadding) * 2, 0, buttonSize.width, buttonSize.height));
}

#pragma mark - private

- (void)yesButtonTapped:(id)sender {
    self.yesButton.selected = YES;
    self.noButton.selected = self.notSureButton.selected = NO;
    [self changeResponse:WitnessResponseYes];
}

- (void)noButtonTapped:(id)sender {
    self.noButton.selected = YES;
    self.yesButton.selected = self.notSureButton.selected = NO;
    [self changeResponse:WitnessResponseNo];
}

- (void)notSureButtonTapped:(id)sender {
    self.notSureButton.selected = YES;
    self.noButton.selected = self.yesButton.selected = NO;
    [self changeResponse:WitnessResponseNotSure];
}

- (void)changeResponse:(WitnessResponse)response {
    if (self.selectedResponse != response) {
        self.selectedResponse = response;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)setUp {
    self.allowNotSureResponse = YES;
    self.selectedResponse = WitnessResponseNone;
    [self setUpButtons];
}

- (void)setUpButtons {
    UIButton *yesButton = ({
        WitnessResponseButton *button = [[WitnessResponseButton alloc] init];
        [button addTarget:self action:@selector(yesButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:WitnessLocalizedString(@"YES", nil) forState:UIControlStateNormal];
        button.image = [UIImage imageNamed:@"yes"];
        button.tintColor = EyewitnessTheme.yesColor;
        [self addSubview:button];
        button;
    });
    self.yesButton = yesButton;

    UIButton *noButton = ({
        WitnessResponseButton *button = [[WitnessResponseButton alloc] init];
        [button addTarget:self action:@selector(noButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:WitnessLocalizedString(@"NO", nil) forState:UIControlStateNormal];
        button.image = [UIImage imageNamed:@"no"];
        button.tintColor = EyewitnessTheme.noColor;
        [self addSubview:button];
        button;
    });
    self.noButton = noButton;

    UIButton *notSureButton = ({
        WitnessResponseButton *button = [[WitnessResponseButton alloc] init];
        [button addTarget:self action:@selector(notSureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:WitnessLocalizedString(@"NOT SURE", nil) forState:UIControlStateNormal];
        [self addSubview:button];
        button;
    });
    self.notSureButton = notSureButton;
}

- (void)reset {
    self.selectedResponse = WitnessResponseNone;
    self.noButton.selected = self.yesButton.selected = self.notSureButton.selected = NO;
}
@end
