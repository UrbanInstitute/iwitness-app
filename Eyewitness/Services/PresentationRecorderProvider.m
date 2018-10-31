#import "PresentationRecorderProvider.h"
#import "PresentationRecorder.h"
#import "VideoRecorder.h"
#import "ScreenCaptureService.h"
#import "Presentation.h"
#import "StitchingQueue.h"
#import "LineupReviewWriter.h"

@interface PresentationRecorderProvider ()
@property (nonatomic, strong) StitchingQueue *stitchingQueue;
@end

@implementation PresentationRecorderProvider

- (instancetype)initWithStitchingQueue:(StitchingQueue *)stitchingQueue {
    if (self = [super init]) {
        self.stitchingQueue = stitchingQueue;
    }
    return self;
}

- (PresentationRecorder *)presentationRecorderForPresentation:(Presentation *)presentation
                                               captureSession:(AVCaptureSession *)captureSession
{
    return [[PresentationRecorder alloc] initWithApplication:[UIApplication sharedApplication]
                                                presentation:presentation
                                               videoRecorder:[[VideoRecorder alloc] initWithCaptureSession:captureSession]
                                        screenCaptureService:[[ScreenCaptureService alloc] init]
                                              stitchingQueue:self.stitchingQueue
                                          lineupReviewWriter:[[LineupReviewWriter alloc] init]];
}

@end
