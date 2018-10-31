@class Presentation;
@class PresentationRecorder;
@class StitchingQueue;

@interface PresentationRecorderProvider : NSObject

- (instancetype)initWithStitchingQueue:(StitchingQueue *)stitchingQueue;

- (PresentationRecorder *)presentationRecorderForPresentation:(Presentation *)presentation
                                               captureSession:(AVCaptureSession *)captureSession;

@end
