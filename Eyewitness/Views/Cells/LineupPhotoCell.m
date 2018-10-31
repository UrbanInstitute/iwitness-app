#import "LineupPhotoCell.h"
#import "LineupPhotoCellDelegate.h"
#import "EyewitnessTheme.h"

@interface LineupPhotoCell ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@property (nonatomic, weak) id<LineupPhotoCellDelegate> delegate;
@end

@implementation LineupPhotoCell

- (void)awakeFromNib {
    [self setEditing:NO];
    self.layer.borderWidth = 1;
    self.layer.borderColor = [EyewitnessTheme darkerGrayColor].CGColor;
}

- (void)configureWithDelegate:(id<LineupPhotoCellDelegate>)delegate {
    self.delegate = delegate;
}

- (IBAction)deleteTapped:(id)sender {
    [self.delegate lineupPhotoCellDidDelete:self];
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;
    self.deleteButton.alpha = editing ? 1 : 0;
}

@end
