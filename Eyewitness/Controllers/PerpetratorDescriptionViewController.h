#import <UIKit/UIKit.h>
#import "PerpetratorDescriptionView.h"

@class PerpetratorDescription;

@interface PerpetratorDescriptionViewController : UIViewController

@property (nonatomic, retain) PerpetratorDescriptionView *view;

- (void)configureWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription;

@end
