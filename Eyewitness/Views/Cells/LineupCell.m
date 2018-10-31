#import "LineupCell.h"
#import "EyewitnessTheme.h"

@interface LineupCell ()
@property (nonatomic, weak) IBOutlet id<LineupCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *caseIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UIButton *editButton;
@property (nonatomic, weak) IBOutlet UIButton *previewButton;
@property (nonatomic, weak) IBOutlet UIButton *presentToWitnessButton;

@end

@implementation LineupCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self updateActionButtonVisibilityForSelected:self.selected];

    self.selectedBackgroundView = [[UIView alloc] init];
    self.selectedBackgroundView.backgroundColor = [EyewitnessTheme darkGrayColor];
}

- (void)updateActionButtonVisibilityForSelected:(BOOL)selected {
    CGFloat alpha = selected ? 1 : 0;
    self.editButton.alpha = alpha;
    self.previewButton.alpha = alpha;
    self.presentToWitnessButton.alpha = alpha;
}

#pragma mark - Property Overrides

- (void)setCaseID:(NSString *)caseID {
    _caseID = caseID;
    self.caseIDLabel.text = caseID;
}

- (void)setDateString:(NSString *)dateString {
    _dateString = dateString;
    self.dateLabel.text = dateString;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [UIView animateWithDuration:0.3 animations:^{
        [self updateActionButtonVisibilityForSelected:selected];
    }];
}

#pragma mark - Actions

- (IBAction) editButtonTapped {
    [self.delegate lineupCellDidRequestEditing:self];
}

- (IBAction) presentToWitnessButtonTapped {
    [self.delegate lineupCellDidRequestPresentation:self];
}

@end
