@class PresentationCell;
@class StitchingProgressIndicatorView;
@class DefaultButton;

@protocol PresentationCellDelegate <NSObject>
- (void)presentationCellDidTapViewPresentation:(PresentationCell *)cell;
@end


@interface PresentationCell : UITableViewCell

@property (nonatomic, weak, readonly) UILabel *dateLabel;
@property (nonatomic, weak, readonly) UILabel *caseIDLabel;
@property (nonatomic, weak, readonly) DefaultButton *viewPresentationButton;
@property (nonatomic, weak, readonly) StitchingProgressIndicatorView *indicatorView;

@end
