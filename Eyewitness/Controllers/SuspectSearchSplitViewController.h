#import <UIKit/UIKit.h>

@class SuspectSearchViewController;
@class SuspectSearchResultsViewController;

@interface SuspectSearchSplitViewController : UIViewController

@property (nonatomic, weak, readonly) SuspectSearchViewController *searchViewController;
@property (nonatomic, weak, readonly) SuspectSearchResultsViewController *resultsViewController;

@end
