#import "PresentationCell.h"
#import "StitchingProgressIndicatorView.h"
#import "DefaultButton.h"

@interface PresentationCell ()
@property (nonatomic, weak, readwrite) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *caseIDLabel;
@property (nonatomic, weak, readwrite) IBOutlet DefaultButton *viewPresentationButton;
@property (nonatomic, weak, readwrite) IBOutlet StitchingProgressIndicatorView *indicatorView;

@property (nonatomic, weak) IBOutlet id<PresentationCellDelegate> delegate;
@end

@implementation PresentationCell

- (IBAction)viewPresentationButtonTapped:(id)sender {
    [self.delegate presentationCellDidTapViewPresentation:self];
}

@end
