#import "ScreenCaptureService.h"
#import "ObserveTouchesGestureRecognizer.h"
#import "EyewitnessTheme.h"
#import "AnalyticsTracker.h"
#import "TouchLatencyAggregator.h"

@interface ScreenCaptureService ()
@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *writerInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (assign, nonatomic) CFTimeInterval captureStartTime;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic, readwrite) NSURL *outputURL;

@property (strong, nonatomic) ObserveTouchesGestureRecognizer *observeTouchesGestureRecognizer;
@property (strong, nonatomic) UIBezierPath *touchPath;

@property (unsafe_unretained, nonatomic) CGColorSpaceRef frameColorSpace;
@property (assign, nonatomic) CMTime lastCapturedFrameTime;

@property (assign, nonatomic) NSUInteger numFramesCaptured;
@property (nonatomic) dispatch_queue_t backgroundResizingQueue;

@property (nonatomic, assign) BOOL skippedLastFrame;
@property (nonatomic, strong) NSMutableSet *availableCaptureBuffers;
@property (nonatomic, strong) NSMutableSet *liveCaptureBuffers;
@end

static NSInteger kFramesPerSecond = 10;
static int32_t kPreferredTimescale = 30;
static CGFloat kTouchPointCircleRadius = 23;

static NSInteger kMaximumCaptureBufferCount = 5;

@implementation ScreenCaptureService

- (instancetype)init {
    if (self = [super init]) {
        TouchLatencyAggregator *touchLatencyAggregator = [[TouchLatencyAggregator alloc] init];
        self.observeTouchesGestureRecognizer = [[ObserveTouchesGestureRecognizer alloc] initWithTarget:nil action:nil touchLatencyAggregator:touchLatencyAggregator];
        self.backgroundResizingQueue = dispatch_queue_create("org.ljaf.eyewitness.background_resizing", DISPATCH_QUEUE_SERIAL);
        self.availableCaptureBuffers = [[NSMutableSet alloc] init];
        self.liveCaptureBuffers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.observeTouchesGestureRecognizer.view removeGestureRecognizer:self.observeTouchesGestureRecognizer];
    self.frameColorSpace = nil; // Required because CGColorSpaceRef's memory is manually managed
    for (NSValue *contextValue in [self.availableCaptureBuffers setByAddingObjectsFromSet:self.liveCaptureBuffers]) {
        CGContextRef context = [contextValue pointerValue];
        CGContextRelease(context);
    }
}

- (void)startCapturingScreenToURL:(NSURL *)outputURL {
    self.outputURL = outputURL;

    [self setupAssetWriterWithURL:outputURL pixelBufferScale:[self frameScale]];

    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];

    self.frameColorSpace = (CGColorSpaceRef)CFAutorelease(CGColorSpaceCreateDeviceRGB());

    [[self captureWindow] addGestureRecognizer:self.observeTouchesGestureRecognizer];

    self.timer = [NSTimer timerWithTimeInterval:1.f/kFramesPerSecond target:self selector:@selector(captureFrame) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];

    [self captureFrame];
}

- (void)setupAssetWriterWithURL:(NSURL *)outputURL pixelBufferScale:(CGFloat)scale {
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:nil];
        UIScreen *screen = [UIScreen mainScreen];
    self.assetWriter.movieFragmentInterval = CMTimeMake(10, 1);

    self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:@{
                                                                                                           AVVideoCodecKey:
#ifdef TARGET_IPHONE_SIMULATOR
                                                                                                           AVVideoCodecH264,
#else
                                                                                                           AVVideoCodecJPEG,
#endif
                                                                                                           AVVideoHeightKey: @(screen.bounds.size.height * scale),
                                                                                                           AVVideoWidthKey: @(screen.bounds.size.width * scale)
                                                                                                           }];
    self.writerInput.expectsMediaDataInRealTime = YES;

    self.pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput
                                                                         sourcePixelBufferAttributes:@{
                                                                                                       (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
                                                                                                       }];
    [self.assetWriter addInput:self.writerInput];
    [self.assetWriter startWriting];
}

- (KSPromise *)stopCapturing {
    [self.timer invalidate];

    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        [self.assetWriter endSessionAtSourceTime:CMTimeMakeWithSeconds(CACurrentMediaTime()-self.captureStartTime, kPreferredTimescale)];
    }

    [self.observeTouchesGestureRecognizer stopObservingTouches];

    KSDeferred *deferred = [KSDeferred defer];

    if (self.assetWriter.error) {
        [[AnalyticsTracker sharedInstance] trackPresentationScreenCaptureFailureWithError:self.assetWriter.error];
        [deferred rejectWithError:self.assetWriter.error];
    } else {
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.assetWriter.error) {
                    [[AnalyticsTracker sharedInstance] trackPresentationScreenCaptureFailureWithError:self.assetWriter.error];
                    [deferred rejectWithError:self.assetWriter.error];
                }
                [deferred resolveWithValue:self.assetWriter.outputURL];
            });
        }];
    }
    return deferred.promise;
}

- (void)captureFrame {
    if (![self.writerInput isReadyForMoreMediaData] || self.assetWriter.status != AVAssetWriterStatusWriting) {
        return;
    }

    CFTimeInterval currentTime = CACurrentMediaTime();
    if (!self.captureStartTime) {
        self.captureStartTime = currentTime;
    }

    CMTime currentFrameTime = CMTimeMakeWithSeconds(currentTime-self.captureStartTime, kPreferredTimescale);
    if (CMTIME_IS_VALID(self.lastCapturedFrameTime) && CMTIME_COMPARE_INLINE(currentFrameTime, <=, self.lastCapturedFrameTime)) {
        return;
    }

    UIWindow *captureWindow = [self captureWindow];
    CGFloat sourceWidth = CGRectGetWidth(captureWindow.bounds);

    if ([self frameScale] != captureWindow.screen.scale) {
        CGContextRef frameCaptureContext;
        UIImage *capturedFrameImage = [self imageByCapturingView:captureWindow context:&frameCaptureContext];
        self.skippedLastFrame = (capturedFrameImage==nil);
        if (!capturedFrameImage) { return; }

        dispatch_async(self.backgroundResizingQueue, ^{
            [self fillAndAppendPixelBufferWithCurrentFrameTime:currentFrameTime
                                                   sourceWidth:sourceWidth
                                                  drawingBlock:^{
                                                      [capturedFrameImage drawAtPoint:CGPointZero];
                                                  }];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSValue *contextValue = [NSValue valueWithPointer:frameCaptureContext];
                [self.liveCaptureBuffers removeObject:contextValue];
                [self.availableCaptureBuffers addObject:contextValue];

                if (self.skippedLastFrame) {
                    [self captureFrame];
                }

            });
        });
    } else {
        [self fillAndAppendPixelBufferWithCurrentFrameTime:currentFrameTime
                                               sourceWidth:sourceWidth
                                              drawingBlock:^{
                                                  [self drawViewWithTouchAnnotations:captureWindow];
                                              }];
    }

    self.lastCapturedFrameTime = currentFrameTime;
}

- (void)fillAndAppendPixelBufferWithCurrentFrameTime:(CMTime)currentFrameTime sourceWidth:(CGFloat)sourceWidth drawingBlock:(void (^)(void))drawingBlock {
    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer(NULL, self.pixelBufferAdaptor.pixelBufferPool, &pixelBuffer);
    if (!pixelBuffer) { return; }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelBytes = CVPixelBufferGetBaseAddress(pixelBuffer);

    CGFloat pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    CGContextRef context = CGBitmapContextCreate(pixelBytes,
                                                 pixelBufferWidth,
                                                 CVPixelBufferGetHeight(pixelBuffer),
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                 self.frameColorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    CGContextTranslateCTM(context, 0, CVPixelBufferGetHeight(pixelBuffer));

    CGFloat scale = pixelBufferWidth / sourceWidth;
    CGContextScaleCTM(context, 1*scale, -1*scale);

    UIGraphicsPushContext(context);
    drawingBlock();
    UIGraphicsPopContext();

    CGContextRelease(context);

    if ([NSThread isMainThread]) {
        [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:currentFrameTime];
        self.numFramesCaptured++;
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (self.assetWriter.status == AVAssetWriterStatusWriting) {
                [self.pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:currentFrameTime];
                self.numFramesCaptured++;
            }
        });
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);
}

- (CGFloat)frameScale {
    static CGFloat frameScaleForCurrentDevice = -1;
    if (frameScaleForCurrentDevice < 0) {
        if ([UIScreen mainScreen].scale > 1) {
            ScreenCaptureService *scaleTestingScreenCaptureService = [[ScreenCaptureService alloc] init];
            NSURL *scaleTestingURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
            [scaleTestingScreenCaptureService setupAssetWriterWithURL:scaleTestingURL pixelBufferScale:2.0f];
            if (!scaleTestingScreenCaptureService.assetWriter.error) {
                frameScaleForCurrentDevice = 2.0f;
            }
            [scaleTestingScreenCaptureService.assetWriter cancelWriting];
            [[NSFileManager defaultManager] removeItemAtURL:scaleTestingURL error:NULL];
        }

        if (frameScaleForCurrentDevice < 0) {
            frameScaleForCurrentDevice = 1.0f;
        }
    }

    return frameScaleForCurrentDevice;
}

- (float)actualFrameCaptureRate {
    CFTimeInterval elapsedTime = CACurrentMediaTime() - self.captureStartTime;
    return (float)(self.numFramesCaptured / elapsedTime);
}
#pragma mark - private

- (UIWindow *)captureWindow {
    return [[[UIApplication sharedApplication] delegate] window];
}

- (void)drawViewWithTouchAnnotations:(UIView *)captureView {
    [captureView drawViewHierarchyInRect:captureView.bounds afterScreenUpdates:NO];
    
    NSSet *activeTouches = [self.observeTouchesGestureRecognizer activeTouches];
    if ([activeTouches count] > 0) {
        UIBezierPath *touchPath = self.touchPath;
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[EyewitnessTheme touchOverlayColor] set];
        
        for (ObservedTouch *touch in activeTouches) {
            CGContextSaveGState(context);
            
            CGPoint touchLocation = touch.location;
            CGContextTranslateCTM(context, touchLocation.x, touchLocation.y);
            
            [touchPath fillWithBlendMode:kCGBlendModeNormal alpha:1.0f-touch.decay];
            CGContextRestoreGState(context);
        }
    }
}

- (UIImage *) imageByCapturingView:(UIView *)captureView context:(CGContextRef *)outContext {
    UIImage *capturedFrameImage;

    CGFloat scale = ((UIWindow *)captureView).screen.scale;

    NSValue *contextValue = [self.availableCaptureBuffers anyObject];
    CGContextRef context = [contextValue pointerValue];
    if (context) {
        [self.availableCaptureBuffers removeObject:contextValue];
    } else if ([self.availableCaptureBuffers count] + [self.liveCaptureBuffers count] < kMaximumCaptureBufferCount) {
        context = CGBitmapContextCreate(NULL, CGRectGetWidth(captureView.bounds)*scale, CGRectGetHeight(captureView.bounds)*scale, 8, 0, self.frameColorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst);

        CGContextTranslateCTM(context, 0, CGBitmapContextGetHeight(context));
        CGContextScaleCTM(context, 1*scale, -1*scale);

        contextValue = [NSValue valueWithPointer:context];
    } else {
        return nil;
    }

    [self.liveCaptureBuffers addObject:contextValue];

    UIGraphicsPushContext(context);
    [self drawViewWithTouchAnnotations:captureView];
    UIGraphicsPopContext();

    CGImageRef capturedFrameImageRef = CGBitmapContextCreateImage(context);

    CGImageRef noInterpolationImageRef = CGImageCreate(CGImageGetWidth(capturedFrameImageRef),
                                                       CGImageGetHeight(capturedFrameImageRef),
                                                       CGImageGetBitsPerComponent(capturedFrameImageRef),
                                                       CGImageGetBitsPerPixel(capturedFrameImageRef),
                                                       CGImageGetBytesPerRow(capturedFrameImageRef),
                                                       CGImageGetColorSpace(capturedFrameImageRef),
                                                       CGImageGetBitmapInfo(capturedFrameImageRef),
                                                       CGImageGetDataProvider(capturedFrameImageRef),
                                                       CGImageGetDecode(capturedFrameImageRef),
                                                       NO,
                                                       kCGRenderingIntentDefault);
    capturedFrameImage = [UIImage imageWithCGImage:noInterpolationImageRef
                                             scale:scale
                                       orientation:UIImageOrientationUp];
    CGImageRelease(noInterpolationImageRef);

    CGImageRelease(capturedFrameImageRef);

    if (outContext) {
        *outContext = context;
    }

    return capturedFrameImage;
}

#pragma mark - Accessors

- (void)setFrameColorSpace:(CGColorSpaceRef)frameColorSpace {
    if (frameColorSpace != _frameColorSpace) {
        CGColorSpaceRetain(frameColorSpace);
        CGColorSpaceRelease(_frameColorSpace);
        _frameColorSpace = frameColorSpace;
    }
}

- (UIBezierPath *)touchPath {
    return [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-kTouchPointCircleRadius, -kTouchPointCircleRadius, kTouchPointCircleRadius*2, kTouchPointCircleRadius*2)];
}

@end
