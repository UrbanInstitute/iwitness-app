#import "FaceDetector.h"

@interface FaceDetector () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) AVCaptureConnection *connection;

@property (nonatomic, readwrite) NSInteger numberOfFacesDetected;
@end

@implementation FaceDetector

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession {
    if (self = [super init]) {
        self.captureSession = captureSession;
        self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];

    }
    return self;
}

- (void)dealloc {
    if (self.metadataOutput) {
        [self.captureSession removeOutput:self.metadataOutput];
    }
}

- (void)startDetecting {
    if (self.connection.enabled) { return; }

    if (![self.captureSession.outputs containsObject:self.metadataOutput]) {
        [self.captureSession addOutput:self.metadataOutput];
    }

    self.connection = [self.metadataOutput.connections firstObject];
    self.connection.enabled = YES;

    if ([[self.metadataOutput availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeFace]) {
        self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
        [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    }
}

- (void)stopDetecting {
    self.connection.enabled = NO;
}

#pragma mark - <AVCaptureMetaOutputObjectsDelegate>

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSInteger faceCount = metadataObjects.count;
    if (faceCount != self.numberOfFacesDetected) {
        self.numberOfFacesDetected = faceCount;
    }
}

@end
