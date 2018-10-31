#import <Foundation/Foundation.h>

@class PresentationStore, Presentation, PresentationRecorderProvider, CaptureSessionProvider, PasswordValidator, PresentationFlowViewController;
@protocol PresentationFlowViewControllerDelegate;

@interface PresentationFlowViewControllerProvider : NSObject

- (instancetype)initWithPresentationRecorderProvider:(PresentationRecorderProvider *)presentationRecorderProvider
                              captureSessionProvider:(CaptureSessionProvider *)captureSessionProvider
                                   passwordValidator:(PasswordValidator *)passwordValidator;

- (PresentationFlowViewController *)presentationFlowViewControllerWithPresentation:(Presentation *)presentation
                                                                      flowDelegate:(id<PresentationFlowViewControllerDelegate>)delegate;

@end
