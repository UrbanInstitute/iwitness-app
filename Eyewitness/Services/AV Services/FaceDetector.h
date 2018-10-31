@interface FaceDetector : NSObject

@property (nonatomic, readonly) NSInteger numberOfFacesDetected;

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession;

- (void)startDetecting;
- (void)stopDetecting;

@end
