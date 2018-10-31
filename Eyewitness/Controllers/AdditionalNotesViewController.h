#import <UIKit/UIKit.h>

@class PerpetratorDescription;

@interface AdditionalNotesViewController : UIViewController
@property (weak, nonatomic, readonly) UILabel *caseIDLabel;
@property (weak, nonatomic, readonly) UITextView *additionalNotesTextView;

- (void)configureWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription;
@end
