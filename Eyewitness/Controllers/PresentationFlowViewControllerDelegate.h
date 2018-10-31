#import <Foundation/Foundation.h>

@class PresentationFlowViewController;

@protocol PresentationFlowViewControllerDelegate <NSObject>
- (void)presentationFlowViewControllerDidFinish:(PresentationFlowViewController *)controller;
@end
