#import <UIKit/UIKit.h>
#import "SuspectSearchView.h"

@class SuspectSearchViewController;
@protocol SuspectSearchViewControllerDelegate;


@interface SuspectSearchViewController : UIViewController<UITextFieldDelegate>
@property (nonatomic, retain) SuspectSearchView *view;
- (void)configureWithCaseID:(NSString *)caseID delegate:(id<SuspectSearchViewControllerDelegate>)delegate;

@end
