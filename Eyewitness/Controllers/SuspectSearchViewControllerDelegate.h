#import <Foundation/Foundation.h>

@class SuspectSearchViewController;

@protocol SuspectSearchViewControllerDelegate <NSObject>

- (void)suspectSearchViewController:(SuspectSearchViewController *)suspectSearchViewController didRequestSearchWithFirstName:(NSString *)firstName lastName:(NSString *)lastName suspectID:(NSString *)suspectID;

@end

