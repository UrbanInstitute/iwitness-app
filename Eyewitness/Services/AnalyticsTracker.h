#import <Foundation/Foundation.h>

@class Mixpanel;

@interface AnalyticsTracker : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithMixpanel:(Mixpanel *)mixpanel;

- (void)trackLineupCreation;
- (void)trackPresentationStarted;
- (void)trackMicrophoneAccessDenied;
- (void)trackPresentationPlaybackWithLength:(NSTimeInterval)presentationLength;
- (void)trackPresentationCompleted;
- (void)trackPresentationVideoRecorderFailureWithError:(NSError *)error;
- (void)trackPresentationScreenCaptureFailureWithError:(NSError *)error;
- (void)trackPresentationVideoStitcherFailureWithError:(NSError *)error;
- (void)trackPresentationVideoStitcherCompletedWithVideoLength:(NSTimeInterval)length
                                   screenCaptureFrameRate:(float)frameRate
                                    videoRecorderFileSize:(unsigned long long)videoRecorderFileSize
                                    screenCaptureFileSize:(unsigned long long)screenCaptureFileSize
                                    stitchedVideoFileSize:(unsigned long long)stitchedVideoFileSize;
@end
