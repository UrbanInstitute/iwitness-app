#import <Foundation/Foundation.h>

@class PresentationCompleteViewController;

@protocol PresentationCompleteViewControllerDelegate <NSObject>
- (void)presentationCompleteViewControllerDidFinish:(PresentationCompleteViewController *)controller;
@end
