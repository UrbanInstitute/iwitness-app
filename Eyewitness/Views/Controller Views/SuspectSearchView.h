#import <UIKit/UIKit.h>

@class DefaultTextField;

@interface SuspectSearchView : UIView

@property (weak, nonatomic) IBOutlet UILabel *caseIDLabel;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *suspectIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@end
