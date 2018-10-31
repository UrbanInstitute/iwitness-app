#import "VideoRecorder.h"
#import "AnalyticsTracker.h"

@interface VideoRecorder () <AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, readwrite, getter=isRecording) BOOL recording;
@property (nonatomic, strong) KSDeferred *deferred;
@end

@implementation VideoRecorder

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession {
    if (self = [super init]) {
        self.captureSession = captureSession;
    }
    return self;
}

- (void)startRecordingToOutputURL:(NSURL *)outputURL {
    if (self.recording) { return; }

    [self.captureSession startRunning];
    if (![outputURL isFileURL]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"outputFileURL must be a file URL" userInfo:nil];
    }
    self.outputURL = outputURL;
    self.recording = YES;
    self.deferred = [KSDeferred defer];

    [self.captureSession addOutput:self.movieFileOutput];

    if (self.movieFileOutput.connections.count > 0) {
        [[[NSFileManager alloc] init] removeItemAtURL:self.outputURL error:NULL];
        [self.movieFileOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
    }
}

- (KSPromise *)stopRecording {
    if (self.recording) {
        self.recording = NO;

        if (self.movieFileOutput.recording) {
            [self.movieFileOutput stopRecording];
        }

#if TARGET_IPHONE_SIMULATOR
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.deferred rejectWithError:[NSError errorWithDomain:kVideoRecorderErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: @"VideoRecorder does not work on simulator" }]];
        });
#endif
    }

    return self.deferred.promise;
}

#pragma mark - <AVCaptureFileOutputRecordingDelegate>

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    void (^invokeCompletion)() = ^{
        if (error) {
            [[AnalyticsTracker sharedInstance] trackPresentationVideoRecorderFailureWithError:error];
            [self.deferred rejectWithError:error];
        } else {
            [self.deferred resolveWithValue:outputFileURL];
        }
        self.captureSession = nil;
    };

    if ([NSThread isMainThread]) {
        invokeCompletion();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), invokeCompletion);
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

#pragma mark - Property Overrides

- (AVCaptureMovieFileOutput *)movieFileOutput {
    if (!_movieFileOutput) {
        self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _movieFileOutput;
}

@end
