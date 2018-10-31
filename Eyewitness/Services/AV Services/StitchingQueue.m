#import "StitchingQueue.h"
#import "Presentation.h"
#import "PresentationStore.h"
#import "VideoStitcherProvider.h"
#import "StitchingQueueObserver.h"
#import "AnalyticsTracker.h"
#import "Lineup.h"

@interface StitchingQueue ()

@property (nonatomic, strong) VideoStitcherProvider *videoStitcherProvider;
@property (nonatomic, strong) NSMutableDictionary *stitchers;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableSet *observers;

@end

@implementation StitchingQueue

- (instancetype)initWithVideoStitcherProvider:(VideoStitcherProvider *)videoStitcherProvider {
    if (self = [super init]) {
        _videoStitcherProvider = videoStitcherProvider;
        _observers = [NSMutableSet set];
        _stitchers = [NSMutableDictionary dictionary];
        _timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:0.1 target:self selector:@selector(pollForProgressUpdates) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)dealloc {
    [_timer invalidate];
}

- (void)addStitchingObserver:(id<StitchingQueueObserver>)observer {
    [self.observers addObject:observer];
}

- (void)removeStitchingObserver:(id<StitchingQueueObserver>)observer {
    [self.observers removeObject:observer];
}

- (void)enqueueStitcherForPresentation:(Presentation *)presentation {
    VideoStitcher *stitcher = [self.videoStitcherProvider videoStitcher];
    self.stitchers[presentation.UUID] = stitcher;

    [[stitcher stitchCameraCaptureAtURL:presentation.temporaryCameraRecordingURL
                 withScreenCaptureAtURL:presentation.temporaryScreenCaptureURL
                              outputURL:presentation.temporaryStitchingURL
                  videoPreviewTimeRange:presentation.videoPreviewTimeRange
                     excludeCameraVideo:presentation.lineup.audioOnly] then:^id(id value) {
        [self trackStitcherCompleted:stitcher forPresentation:presentation];
        [self.stitchers removeObjectForKey:presentation.UUID];
        [presentation attachStitchedVideo];

        for (id <StitchingQueueObserver> observer in self.observers) {
            [observer stitchingQueue:self didCompleteStitchingForPresentationUUID:presentation.UUID];
        }

        return nil;
    } error:^id(NSError *error) {
        [self.stitchers removeObjectForKey:presentation.UUID];
        for (id <StitchingQueueObserver> observer in self.observers) {
            [observer stitchingQueue:self didCancelStitchingForPresentationUUID:presentation.UUID];
        }

        if (error && !([error.domain isEqualToString:kVideoStitcherErrorDomain] && error.code == kVideoStitcherErrorBackgroundTimeExpired)) {
            [[AnalyticsTracker sharedInstance] trackPresentationVideoStitcherFailureWithError:error];
        }
        return nil;
    }];
}

- (VideoStitcher *)stitcherForPresentation:(Presentation *)presentation {
    VideoStitcher *stitcher = self.stitchers[presentation.UUID];
    return stitcher;
}

#pragma mark - Private

- (void)pollForProgressUpdates {
    for (NSString *presentationUUID in self.stitchers.allKeys) {
        VideoStitcher *stitcher = self.stitchers[presentationUUID];

        for (id<StitchingQueueObserver> observer in self.observers) {
            [observer stitchingQueue:self didUpdateProgress:stitcher.progress forPresentationUUID:presentationUUID];
        }
    }
}

- (void) trackStitcherCompleted:(VideoStitcher *)stitcher forPresentation:(Presentation *)presentation {
    NSNumber *videoRecorderFileSize = [presentation.temporaryCameraRecordingURL resourceValuesForKeys:@[NSURLFileSizeKey] error:NULL][NSURLFileSizeKey];
    NSNumber *screenCaptureFileSize = [presentation.temporaryScreenCaptureURL resourceValuesForKeys:@[NSURLFileSizeKey] error:NULL][NSURLFileSizeKey];
    NSNumber *stitchedVideoFileSize = [presentation.temporaryStitchingURL resourceValuesForKeys:@[NSURLFileSizeKey] error:NULL][NSURLFileSizeKey];

    AVAssetTrack *screenCaptureVideoTrack = [[AVURLAsset URLAssetWithURL:presentation.temporaryScreenCaptureURL options:nil] tracksWithMediaType:AVMediaTypeVideo].firstObject;
    [screenCaptureVideoTrack loadValuesAsynchronouslyForKeys:@[@"timeRange", @"nominalFrameRate"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSTimeInterval duration = CMTimeGetSeconds(screenCaptureVideoTrack.timeRange.duration);
            float frameRate = screenCaptureVideoTrack.nominalFrameRate;

            [[AnalyticsTracker sharedInstance] trackPresentationVideoStitcherCompletedWithVideoLength:duration
                                                                          screenCaptureFrameRate:frameRate
                                                                           videoRecorderFileSize:[videoRecorderFileSize unsignedLongLongValue]
                                                                           screenCaptureFileSize:[screenCaptureFileSize unsignedLongLongValue]
                                                                           stitchedVideoFileSize:[stitchedVideoFileSize unsignedLongLongValue]];
        });
    }];
}

@end
