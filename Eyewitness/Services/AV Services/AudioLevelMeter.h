@interface AudioLevelMeter : NSObject

@property (nonatomic, readonly) float averagePowerLevel;
@property (nonatomic, readonly) float peakHoldLevel;

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession;
- (void)startMetering;
- (void)stopMetering;

@end
