#import <UIKit/UIKit.h>

@class PerpetratorDescription;

@interface PerpetratorAttributesTableViewController : UITableViewController
@property (weak, nonatomic, readonly) UIButton *additionalDescriptionTapToEditButton;

- (void)configureWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription;
@end
