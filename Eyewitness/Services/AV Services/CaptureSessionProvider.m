#import "CaptureSessionProvider.h"

@implementation CaptureSessionProvider

- (AVCaptureSession *)captureSession {
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    [self addVideoInputToCaptureSession:captureSession withError:NULL];
    [self addAudioInputToCaptureSession:captureSession withError:NULL];
    return captureSession;
}

#pragma mark - Private

- (BOOL)addVideoInputToCaptureSession:(AVCaptureSession *)captureSession withError:(NSError **)error {
    AVCaptureDevice *videoCaptureDevice = [self frontCameraDevice];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:error];
    if (videoInput) {
        [captureSession addInput:videoInput];
        return YES;
    }
    return NO;
}

- (BOOL)addAudioInputToCaptureSession:(AVCaptureSession *)captureSession withError:(NSError **)error {
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:error];
    if (audioInput) {
        [captureSession addInput:audioInput];
        return YES;
    }
    return NO;
}

- (AVCaptureDevice *)frontCameraDevice {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

@end
