#import <Foundation/Foundation.h>

@class ScreenCaptureService, RecordingTimeAvailableCalculator;

@interface RecordingTimeAvailableCalculatorProvider : NSObject

- (instancetype)initWithScreenCaptureService:(ScreenCaptureService *)screenCaptureService;
- (RecordingTimeAvailableCalculator *)recordingTimeAvailableCalculator;

@end
