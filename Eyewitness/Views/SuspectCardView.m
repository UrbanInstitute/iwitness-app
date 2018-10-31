#import "UIImageView+FocusOnRect.h"
#import "SuspectCardView.h"
#import "EyewitnessTheme.h"
#import "FaceLoader.h"
#import "Person.h"
#import "Portrayal.h"

static const CGFloat kFixedWidth = 440.f;
static const CGFloat kContentPadding = 12.f;
static const CGFloat kNameLabelBottomPadding = 5.f;
static const CGFloat kImageViewHeight = 163.f;
static const CGFloat kImageViewWidth = 202.f;
static const CGFloat kImageViewRightPadding = 18.f;
static const CGFloat kNameLabelWidth = kFixedWidth - kImageViewWidth - kContentPadding - kContentPadding - kImageViewRightPadding;
static const CGFloat kLeftLabelX = kContentPadding + kImageViewWidth + kImageViewRightPadding;
static const CGFloat kMaxTagLabelWidth = 70.f;
static const CGFloat kRightLabelX = kContentPadding + kImageViewWidth + kImageViewRightPadding + kMaxTagLabelWidth;
static const CGFloat kOtherLabelWidth = kFixedWidth - kImageViewWidth - kContentPadding - kContentPadding - kImageViewRightPadding - kMaxTagLabelWidth;
static const CGFloat kNameLabelYOffset = 4.0f;

@interface SuspectCardView ()
@property (strong, nonatomic, readwrite) UIButton *deleteButton;
@property (strong, nonatomic, readwrite) UIImageView *imageView;
@property (strong, nonatomic, readwrite) UILabel *nameLabel;
@property (strong, nonatomic, readwrite) UILabel *dateOfBirthLabel, *dateOfBirthTagLabel;
@property (strong, nonatomic, readwrite) UILabel *systemIDLabel, *systemIDTagLabel;
@property (strong, nonatomic, readwrite) UILabel *heightLabel, *heightTagLabel;
@property (strong, nonatomic, readwrite) UILabel *weightLabel, *weightTagLabel;
@property (strong, nonatomic, readwrite) UILabel *raceLabel, *raceTagLabel;
@property (strong, nonatomic, readwrite) UILabel *hairLabel, *hairTagLabel;
@property (strong, nonatomic, readwrite) UILabel *eyesLabel, *eyesTagLabel;
@property (strong, nonatomic, readwrite) NSArray *demographicsLabels;
@end

@implementation SuspectCardView

- (void)awakeFromNib {
    [self setUpView];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self.deleteButton moveCorner:ViewCornerTopRight toPoint:CGPointMake(kFixedWidth - kContentPadding, kContentPadding)];

    self.imageView.frame = CGRectMake(kContentPadding, kContentPadding, kImageViewWidth, kImageViewHeight);

    self.nameLabel.frame = CGRectMake(kLeftLabelX, kContentPadding - kNameLabelYOffset, kNameLabelWidth, [self.nameLabel.text heightWithWidth:kNameLabelWidth font:self.nameLabel.font]);

    CGFloat nextLabelY = CGRectGetMaxY(self.nameLabel.frame) + kNameLabelBottomPadding;

    for (NSArray *labelPair in self.demographicsLabels) {
        UILabel *label = labelPair[0];
        UILabel *tagLabel = labelPair[1];
        label.frame = CGRectMake(kRightLabelX, nextLabelY, kOtherLabelWidth, [self.dateOfBirthLabel.text heightWithWidth:kOtherLabelWidth font:self.dateOfBirthLabel.font]);
        tagLabel.frame = CGRectMake(kLeftLabelX, nextLabelY, kMaxTagLabelWidth, self.dateOfBirthTagLabel.intrinsicContentSize.height);
        nextLabelY += CGRectGetHeight(label.frame);
    }
}

- (CGSize)intrinsicContentSize {
    CGFloat calculatedHeight = kContentPadding;
    calculatedHeight += [self.nameLabel.text heightWithWidth:kNameLabelWidth font:self.nameLabel.font];
    calculatedHeight += kNameLabelBottomPadding;

    for (NSArray *labelPair in self.demographicsLabels) {
        UILabel *label = labelPair[0];
        calculatedHeight += [label.text heightWithWidth:kOtherLabelWidth font:label.font];
    }
    calculatedHeight += kContentPadding;
    return CGSizeMake(kFixedWidth, MAX(calculatedHeight, kImageViewHeight + kContentPadding * 2));
}

- (void)configureWithPerson:(Person *)person faceLoader:(FaceLoader *)faceLoader {
    self.nameLabel.text = person.fullName ?: @"";
    self.systemIDLabel.text = person.systemID ? [@"#" stringByAppendingString:person.systemID] : @"";
    self.dateOfBirthLabel.text = person.dateOfBirth ? [self.dateOfBirthFormatter stringFromDate:person.dateOfBirth] : @"";
    self.heightLabel.text = @"";
    self.weightLabel.text = @"";
    self.raceLabel.text = @"";
    self.hairLabel.text = @"";
    self.eyesLabel.text = @"";

    self.imageView.image = nil;
    if (person.selectedPortrayal.photoURL) { //MOK
        NSURL * susPhotoUrl = (NSURL *)person.selectedPortrayal.photoURL;
        [faceLoader loadFaceWithURL:susPhotoUrl completion:^(UIImage *image, CGRect faceRect, NSError *error) {
            self.imageView.image = image;
            [self.imageView focusOnImageRect:faceRect];
        }];
    }

    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

#pragma mark - private

- (NSDateFormatter *)dateOfBirthFormatter {
    static NSDateFormatter *dateOfBirthFormatter;
    if (!dateOfBirthFormatter) {
        dateOfBirthFormatter = [[NSDateFormatter alloc] init];
        [dateOfBirthFormatter setDateFormat:@"M/d/yyyy"];
    }
    return dateOfBirthFormatter;
}

- (UILabel *)createChildLabelWithFont:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [self addSubview:label];
    return label;
}

- (void)setUpView {
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = EyewitnessTheme.grayColor.CGColor;
    self.backgroundColor = [EyewitnessTheme lightGrayColor];

    [self createSubviews];
}

- (void)createSubviews {
    self.nameLabel = [self createChildLabelWithFont:EyewitnessTheme.portrayalCardNameFont];
    self.dateOfBirthLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];
    self.systemIDLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];
    self.heightLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];
    self.weightLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];
    self.raceLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];
    self.hairLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];
    self.eyesLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailValueFont];

    self.dateOfBirthTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.dateOfBirthTagLabel.text = @"DOB:";

    self.systemIDTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.systemIDTagLabel.text = @"ID:";

    self.heightTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.heightTagLabel.text = @"Height:";

    self.weightTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.weightTagLabel.text = @"Weight:";

    self.raceTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.raceTagLabel.text = @"Race:";

    self.hairTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.hairTagLabel.text = @"Hair:";

    self.eyesTagLabel = [self createChildLabelWithFont:EyewitnessTheme.tableDetailLabelFont];
    self.eyesTagLabel.text = @"Eyes:";

    self.demographicsLabels = @[
            @[self.dateOfBirthLabel, self.dateOfBirthTagLabel],
            @[self.systemIDLabel, self.systemIDTagLabel],
            @[self.heightLabel, self.heightTagLabel],
            @[self.weightLabel, self.weightTagLabel],
            @[self.raceLabel, self.raceTagLabel],
            @[self.hairLabel, self.hairTagLabel],
            @[self.eyesLabel, self.eyesTagLabel]
    ];

    self.imageView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.borderWidth = 1.0f;
        imageView.layer.borderColor = UIColor.blackColor.CGColor;
        imageView.clipsToBounds = YES;

        [self addSubview:imageView];
        imageView;
    });

    self.deleteButton = ({
        UIButton *deleteButton = [[UIButton alloc] init];
        deleteButton.accessibilityLabel = @"Delete Suspect";
        deleteButton.hidden = YES;
        UIImage *iconImage = [UIImage imageNamed:@"ew-icon_trash-44"];
        [deleteButton setBackgroundImage:iconImage forState:UIControlStateNormal];
        [deleteButton resizeTo:iconImage.size];
        [self addSubview:deleteButton];
        deleteButton;
    });
}

@end
