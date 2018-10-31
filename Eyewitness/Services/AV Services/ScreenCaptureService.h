#import <Foundation/Foundation.h>

static NSString *kScreenCaptureServiceErrorDomain = @"org.arnoldfoundation.Eyewitness.ScreenCaptureServiceError";

@interface ScreenCaptureService : NSObject

@property (nonatomic, strong, readonly) NSURL *outputURL;

- (void)startCapturingScreenToURL:(NSURL *)outputURL;
- (KSPromise *)stopCapturing;

- (void)captureFrame;

- (CGFloat)frameScale;

- (float)actualFrameCaptureRate;
@end
