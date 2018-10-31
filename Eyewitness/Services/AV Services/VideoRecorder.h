typedef void (^VideoRecorderCompletionBlock)(NSURL *movieFileURL, NSError *error);

static NSString *kVideoRecorderErrorDomain = @"org.arnoldfoundation.Eyewitness.VideoRecorderError";

@interface VideoRecorder : NSObject

@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly) NSURL *outputURL;

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession;
- (void)startRecordingToOutputURL:(NSURL *)outputURL;
- (KSPromise *)stopRecording;

@end
