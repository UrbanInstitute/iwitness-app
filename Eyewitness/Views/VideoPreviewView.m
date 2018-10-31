#import "VideoPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoPreviewView ()
@end

@implementation VideoPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        ((AVCaptureVideoPreviewLayer *)self.layer).session = captureSession;
        self.accessibilityLabel = @"VideoPreview";
        [self.layer.sublayers makeObjectsPerformSelector:@selector(setActions:)
                                              withObject:@{ @"position": [NSNull null], @"sublayerTransform": [NSNull null] }];

        UIImageView *imageView = [UIImageView imageViewWithImageNamed:@"video-preview-overlay"];
        [self addSubview:imageView];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self startCaptureSession];
}

- (void)startCaptureSession {
    AVCaptureSession *captureSession = ((AVCaptureVideoPreviewLayer *)self.layer).session;
    if(captureSession && !captureSession.isRunning) {
        [captureSession startRunning];
    }
}

@end
