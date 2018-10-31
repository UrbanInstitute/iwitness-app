#import <Foundation/Foundation.h>

@class SuspectSearchViewController;
@class SuspectSearchSplitViewController;

@interface SuspectSearchSplitViewControllerProvider : NSObject

- (SuspectSearchSplitViewController *)suspectSearchSplitViewControllerWithCaseID:(NSString *)caseID;

@end
