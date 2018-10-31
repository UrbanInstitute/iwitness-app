#import <UIKit/UIKit.h>

@interface PerpetratorDescriptionView : UIView

@property (nonatomic, weak) IBOutlet UILabel *caseIDLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *descriptionScrollView;

@end
